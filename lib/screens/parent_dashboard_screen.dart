import 'leave_application_screen.dart';
import 'contact_teacher_screen.dart';
import 'parent_profile_page.dart';
import 'fee_payments_screen.dart';
import 'parent_progress_page.dart';
import '../services/parent_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:achiver_app/screens/reports_zone_page.dart';
import 'package:flutter/material.dart';
import 'notification_page.dart';

import 'parent_progress_page.dart' as parent_progress;

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final ParentService _parentService = ParentService();
  Map<String, dynamic>? _parentData;
  bool _isLoading = true;
  bool _isLoadingChildren = true;
  String? _childrenError;
  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _loadParentData();
    _fetchChildren();

    /* Backend TODO: Fetch parent dashboard data from backend (API call, database read) */
  }

  Future<void> _loadParentData() async {
    try {
      final parentData = await _parentService.getParentProfile();
      print("parentData: ${parentData['name']}");
      if (mounted) {
        setState(() {
          _parentData = parentData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchChildren() async {
    setState(() {
      _isLoadingChildren = true;
      _childrenError = null;
    });
    try {
      print('Fetching parent profile...');
      final parentProfile = await ParentService()
          .getParentProfile()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Loading children timed out. Please check your connection.';
      });
      print('Parent profile fetched: ' + parentProfile.toString());
      final children =
          List<Map<String, dynamic>>.from(parentProfile['children'] ?? []);
      print('Children loaded: ${children.length}');
      setState(() {
        _children = children;
        _isLoadingChildren = false;
      });
    } catch (e) {
      print('Error loading children: $e');
      setState(() {
        _childrenError = 'Failed to load children: $e';
        _isLoadingChildren = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          title: const Text(
            'Parent Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChildInfoCard(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildAttendanceAndGrades(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue[800], size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_parentData?['name'] ?? ''}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${_parentData?['phone'] ?? ''}",
                  style: TextStyle(
                    color: Colors.blue[50],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          children: [
            _buildActionButton(
              'Leave\nApplication',
              Icons.event_busy_rounded,
              Colors.orange[400]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveApplicationScreen(),
                ),
              ),
            ),
            _buildActionButton(
              'Contact\nTeacher',
              Icons.chat_bubble_outline_rounded,
              Colors.green[400]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactTeacherScreen(),
                ),
              ),
            ),
            _buildActionButton(
              'Progress',
              Icons.assessment_rounded,
              Colors.purple[400]!,
              onTap: () async {
                if (_children.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No children found for this parent.')),
                  );
                  return;
                }
                if (_children.length == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          parent_progress.ProgressPage(child: _children[0]),
                    ),
                  );
                } else {
                  final selected = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        title: const Text('Select Child'),
                        children: _children.map((child) {
                          final name =
                              child['name'] ?? child['fullName'] ?? 'Unknown';
                          return SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, child),
                            child: Text(name),
                          );
                        }).toList(),
                      );
                    },
                  );
                  if (selected != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            parent_progress.ProgressPage(child: selected),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceAndGrades() {
    if (_children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate average attendance and grade across all children
    double totalAttendance = 0;
    double totalGradeScore = 0;
    int validChildren = 0;

    for (var child in _children) {
      final attendance = child['attendance'] as Map<String, dynamic>?;
      final grades = child['grades'] as Map<String, dynamic>?;

      if (attendance != null && attendance['percentage'] != null) {
        totalAttendance += attendance['percentage'];
        validChildren++;
      }

      if (grades != null && grades['averageScore'] != null) {
        totalGradeScore += grades['averageScore'];
      }
    }

    final averageAttendance =
        validChildren > 0 ? totalAttendance / validChildren : 0;
    final averageGradeScore =
        validChildren > 0 ? totalGradeScore / validChildren : 0;
    final averageGrade = _calculateGrade(averageGradeScore.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Attendance',
                '${averageAttendance.toStringAsFixed(1)}%',
                Icons.calendar_today,
                Colors.green,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Average Grade',
                averageGrade,
                Icons.grade,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    if (score >= 50) return 'E';
    return 'F';
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color[700], size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
