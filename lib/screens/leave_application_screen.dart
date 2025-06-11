import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/LeaveService.dart';
import '../services/ProfileService.dart';
import '../services/auth_service.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedLeaveType = 'Sick Leave';
  bool _isUrgent = false;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _selectedChildRollNumber = '';
  List<String> _childrenRollNumbers = [];
  bool _isLoadingChildren = true;

  final List<String> _leaveTypes = [
    'Sick Leave',
    'Family Emergency',
    'Personal Leave',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadChildrenRollNumbers();
  }

  Future<void> _loadChildrenRollNumbers() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        throw 'Parent ID not found. Please login again.';
      }
      
      // Fetch parent's children roll numbers
      final children = await ProfileService().getParentChildren(userId);
      if (children.isEmpty) {
        throw 'No children found in your profile. Please add your children first.';
      }

      setState(() {
        _childrenRollNumbers = children.map((child) => child['rollNumber'].toString()).toList();
        if (_childrenRollNumbers.isNotEmpty) {
          _selectedChildRollNumber = _childrenRollNumbers[0];
        }
        _isLoadingChildren = false;
      });
    } catch (e) {
      setState(() => _isLoadingChildren = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int _calculateLeaveDays() {
    return _endDate.difference(_startDate).inDays + 1;
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      // Get current user ID and verify parent
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();
      if (userId == null || userType != 'parent') {
        throw 'Only parents can apply for leave. Please login as a parent.';
      }

      // Submit leave
      await LeaveService().applyLeaveForChild(
        childRollNumber: _selectedChildRollNumber,
        leaveType: _selectedLeaveType,
        reason: _reasonController.text.trim(),
        fromDate: _startDate,
        toDate: _endDate,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Your leave application has been submitted successfully.'),
              const SizedBox(height: 15),
              Text('Reference ID: #${DateTime.now().millisecondsSinceEpoch}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        title: const Text(
          'Leave Application',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Colors.indigo[700],
                padding: const EdgeInsets.all(20),
                child: _buildStudentInfo(),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLeaveTypeSection()
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildDateSection()
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildReasonSection()
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideX(),
                    const SizedBox(height: 24),
                    _buildSubmitButton()
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 500.ms)
                        .slideY(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    if (_isLoadingChildren) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_childrenRollNumbers.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No children found. Please add your children to your profile.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Child',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedChildRollNumber,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _childrenRollNumbers.map((String rollNumber) {
                return DropdownMenuItem<String>(
                  value: rollNumber,
                  child: Text('Roll Number: $rollNumber'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedChildRollNumber = newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.indigo[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Leave Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLeaveType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _leaveTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedLeaveType = newValue);
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Urgent Leave Request'),
              subtitle: const Text('Mark if this is an urgent application'),
              value: _isUrgent,
              activeColor: Colors.red,
              onChanged: (bool value) {
                setState(() => _isUrgent = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.indigo[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Leave Duration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Start Date',
                    _startDate,
                    () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'End Date',
                    _endDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Total Leave Days: ${_calculateLeaveDays()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, color: Colors.indigo[700], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.indigo[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Reason for Leave',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Please provide detailed reason for leave...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a reason for leave';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _isSubmitting ? null : _submitApplication,
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
