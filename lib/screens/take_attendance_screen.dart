import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/teacher_profile_service.dart';
import '../services/student_service.dart';
import '../services/AttendanceService.dart';
import 'package:intl/intl.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final _attendanceService = AttendanceService();
  List<String> _classes = ["class 6", "class 7", "class 8", "class 9", "class 10"];
  String? _selectedClass;
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  String? _selectedSection;
  Map<String, bool> _attendance = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _existingAttendance;
  bool _isCheckingAttendance = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _existingAttendance = null;
      });
      if (_selectedClass != null && _selectedSection != null) {
        _checkExistingAttendance();
      }
    }
  }

  Future<void> _checkExistingAttendance() async {
    if (_selectedClass == null || _selectedSection == null) return;

    setState(() {
      _isCheckingAttendance = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendance = await _attendanceService.checkAttendanceMarked(
        _selectedClass!,
        _selectedSection!,
        formattedDate,
      );

      setState(() {
        _existingAttendance = attendance;
        if (attendance != null) {
          _attendance = Map<String, bool>.from(attendance['attendance'] ?? {});
        }
        _isCheckingAttendance = false;
      });

      if (attendance != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance already marked for this date'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isCheckingAttendance = false;
      });
    }
  }

  Future<void> fetchStudentsForClass(String className, String section) async {
    setState(() {
      _isLoading = true;
      _existingAttendance = null;
    });
    try {
      final students = await _attendanceService.getStudentsByClassAndSection(className, section);
      setState(() {
        _students = students;
        _attendance = {
          for (var student in students) 
            student['id']: false
        };
        _isLoading = false;
      });
      _checkExistingAttendance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching students: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Take Attendance',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _selectedClass != null && _selectedSection != null
                  ? '$_selectedClass - $_selectedSection'
                  : 'Select Class and Section',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: const Text('Select Class'),
                          value: _selectedClass,
                          items: _classes
                              .map((grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClass = value;
                              _attendance.clear();
                              _existingAttendance = null;
                            });
                            if (value != null && _selectedSection != null) {
                              fetchStudentsForClass(value, _selectedSection!);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: const Text('Select Section'),
                          value: _selectedSection,
                          items: _sections
                              .map((section) => DropdownMenuItem(
                                    value: section,
                                    child: Text(section),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSection = value;
                              _attendance.clear();
                              _existingAttendance = null;
                            });
                            if (value != null && _selectedClass != null) {
                              fetchStudentsForClass(_selectedClass!, value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM d, yyyy').format(_selectedDate),
                              ),
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.blue[700]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_students.length} Students',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isCheckingAttendance)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_existingAttendance != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attendance marked for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isLoading && _students.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  if (_existingAttendance == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 1),
                      child: Row(
                        children: [
                          Text(
                            'Mark All Present',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _attendance.values.every((v) => v),
                            activeColor: Colors.blue[700],
                            onChanged: (bool value) {
                              setState(() {
                                for (var key in _attendance.keys) {
                                  _attendance[key] = value;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['id'];
                        final isPresent = _attendance[studentId] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  isPresent ? Colors.green[50] : Colors.grey[100],
                              child: Text(
                                student['name'].toString().split(' ')[0][0],
                                style: TextStyle(
                                  color:
                                      isPresent ? Colors.green[700] : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Roll No. ${student['rollNo']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: _existingAttendance != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isPresent ? 'Present' : 'Absent',
                                      style: TextStyle(
                                        color: isPresent
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _attendance[studentId] = true;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isPresent ? Colors.green : Colors.grey[200],
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          'Present',
                                          style: TextStyle(
                                            color:
                                                isPresent ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _attendance[studentId] = false;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              !isPresent ? Colors.red : Colors.grey[200],
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          'Absent',
                                          style: TextStyle(
                                            color:
                                                !isPresent ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          if (!_isLoading && _students.isNotEmpty && _existingAttendance == null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Attendance',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitting ? Colors.blue[400] : Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitAttendance,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_selectedClass == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class and section')),
      );
      return;
    }
    
    if (_attendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to submit')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      await _attendanceService.markAttendance(
        className: _selectedClass!,
        section: _selectedSection!,
        date: formattedDate,
        studentAttendance: _attendance,
        remarks: 'Regular attendance',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
