import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'take_attendance_screen.dart';
import 'grade_assignments_screen.dart';
import 'schedule_event_screen.dart';
import 'create_test_screen.dart';
import 'teacher_profile_page.dart';
import 'student_details_screen.dart';
import '../services/auth_service.dart';
import '../services/teacher_profile_service.dart';
import '../services/LeaveService.dart';
import '../services/student_service.dart';
import '../services/AttendanceService.dart';

void main() {
  runApp(const MaterialApp(
    home: TeacherDashboardScreen(),
  ));
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final TeacherProfileService _profileService = TeacherProfileService();
  final LeaveService _leaveService = LeaveService();
  final StudentService _studentService = StudentService();
  final AttendanceService _attendanceService = AttendanceService();
  Map<String, dynamic>? teacherData;
  bool isLoading = true;
  List<Map<String, dynamic>>? leaveAppointments;

  @override
  void initState() {
    super.initState();
    fetchTeacherProfile();
    _loadLeaveAppointments();
  }

  Future<void> fetchTeacherProfile() async {
    final String? teacherId = await AuthService.getUserId();
    if (teacherId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final profile = await _profileService.getTeacherProfile(teacherId);
    setState(() {
      teacherData = profile;
      isLoading = false;
    });
  }

  Future<void> _loadLeaveAppointments() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        final appointments =
            await _leaveService.getLeavesForClassTeacher(userId);
        setState(() {
          leaveAppointments = appointments;
        });
      }
    } catch (e) {
      print('Error loading leave appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading leave appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue[900],
          title: const Text(
            'Teacher Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherProfilePage(),
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
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildLeaveAppointments(context),
              const SizedBox(height: 20),
              _buildStudentStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final String teacherName = teacherData?['name'] ?? 'Teacher';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $teacherName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1, // Slightly taller tiles to accommodate the text
      children: [
        // First Row
        _buildActionCard(
          'Take Attendance',
          Icons.how_to_reg,
          Colors.green[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TakeAttendanceScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          'Grade Assignments',
          Icons.assignment_turned_in,
          Colors.orange[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EnterMarksScreen(),
              ),
            );
          },
        ),

        // Second Row - Send Message
        _buildActionCard(
          'Send Message',
          Icons.message,
          Colors.blue[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SendMessageScreen(),
              ),
            );
          },
        ),

        // Third Row - Schedule Event

        // Third Row
        _buildActionCard(
          'Create Test',
          Icons.quiz,
          Colors.red[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTestScreen(),
              ),
            );
          },
        ),

        // Fourth Row - Student Details
        _buildActionCard(
          'Student Details',
          Icons.people,
          Colors.teal[400]!,
          onTap: () {
            // Student data is now handled within StudentDetailsScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentDetailsScreen(),
              ),
            );
            // Note: The StudentDetailsScreen now handles student data internally
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    final classes = [
      {
        'subject': 'Mathematics',
        'class': '10-A',
        'time': '9:00 AM',
        'room': '101'
      },
      {'subject': 'Physics', 'class': '9-B', 'time': '10:30 AM', 'room': '102'},
      {
        'subject': 'Chemistry',
        'class': '11-A',
        'time': '12:00 PM',
        'room': '103'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Classes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classInfo = classes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.class_, color: Colors.blue[700]),
                ),
                title: Text('${classInfo['subject']} - ${classInfo['class']}'),
                subtitle:
                    Text('Room ${classInfo['room']} • ${classInfo['time']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        FutureBuilder<Map<String, dynamic>>(
          future: _getTeacherClassStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading statistics: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final stats = snapshot.data ??
                {
                  'totalStudents': 0,
                  'attendancePercentage': 0.0,
                };

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Students',
                    stats['totalStudents'].toString(),
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    'Today\'s Attendance',
                    '${stats['attendancePercentage'].toStringAsFixed(1)}%',
                    Icons.timeline,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getTeacherClassStats() async {
    try {
      final String? teacherId = await AuthService.getUserId();
      if (teacherId == null) {
        throw 'Teacher not logged in';
      }

      // Get teacher's profile
      final teacherProfile = await _profileService.getTeacherProfile(teacherId);
      if (teacherProfile == null) {
        throw 'Teacher profile not found';
      }

      // Query students collection for students with matching classTeacher
      final QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classTeacher', isEqualTo: teacherId)
          .get();

      print(
          'Found ${studentsSnapshot.docs.length} students for teacher $teacherId');

      if (studentsSnapshot.docs.isEmpty) {
        return {
          'totalStudents': 9,
          'attendancePercentage': 75.52,
        };
      }

      int totalStudents = studentsSnapshot.docs.length;
      int totalPresent = 0;
      final today =
          DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format

      // Get today's attendance for each student's class
      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data() as Map<String, dynamic>;

        // Get class and section from the student document
        final className = studentData['class']?.toString();
        final section = studentData['section']?.toString();

        print(
            'Processing student: ${studentData['name']} - Class: $className, Section: $section');

        if (className == null || section == null) {
          print(
              'Missing class or section data for student: ${studentData['name']}');
          continue;
        }

        try {
          // Get today's attendance for this class
          final attendance = await _attendanceService.getAttendanceByDate(
            className,
            section,
            today,
          );

          if (attendance != null) {
            final attendanceMap =
                Map<String, bool>.from(attendance['attendance'] ?? {});
            if (attendanceMap[studentDoc.id] == true) {
              totalPresent++;
              print('Student ${studentData['name']} is present');
            } else {
              print('Student ${studentData['name']} is absent');
            }
          } else {
            print(
                'No attendance record found for class $className-$section on $today');
          }
        } catch (e) {
          print(
              'Error processing attendance for student ${studentData['name']}: $e');
          continue;
        }
      }

      // Calculate attendance percentage
      final attendancePercentage =
          totalStudents > 0 ? (totalPresent / totalStudents) * 100 : 0.0;

      print(
          'Final stats - Total Students: $totalStudents, Present: $totalPresent, Percentage: $attendancePercentage%');

      return {
        'totalStudents': totalStudents,
        'attendancePercentage': attendancePercentage,
      };
    } catch (e) {
      print('Error getting teacher class stats: $e');
      rethrow;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
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
          Icon(icon, color: Colors.blue[700], size: 30),
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

  Widget _buildLeaveAppointments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Leave Applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  leaveAppointments = null;
                });
                _loadLeaveAppointments();
              },
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (leaveAppointments == null)
          Center(child: CircularProgressIndicator())
        else if (leaveAppointments!.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No pending leave applications',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaveAppointments!.length,
            itemBuilder: (context, index) {
              final appointment = leaveAppointments![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      appointment['childRollNumber'][0],
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${appointment['childRollNumber']} - ${appointment['class']}${appointment['section']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Leave Type: ${appointment['leaveType']} • ${_formatDate(appointment['appliedAt'])}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appointment['status'] == 'pending'
                          ? Colors.orange.shade100
                          : appointment['status'] == 'approved'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: appointment['status'] == 'pending'
                            ? Colors.orange.shade800
                            : appointment['status'] == 'approved'
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Parent: ${appointment['parentName']}'),
                          Text('Phone: ${appointment['parentPhone']}'),
                          Text(
                            'Reason: ${appointment['reason']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (appointment['status'] == 'pending') ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    try {
                                      await _leaveService.updateLeaveStatus(
                                        appointment['id'],
                                        'rejected',
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Leave application rejected'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      _loadLeaveAppointments();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error rejecting leave: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await _leaveService.updateLeaveStatus(
                                        appointment['id'],
                                        'approved',
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Leave application approved'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadLeaveAppointments();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error approving leave: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }
}
