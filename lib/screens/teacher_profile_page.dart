import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/teacher_profile_service.dart';
import '../services/LeaveService.dart';
import 'teacher_resources.dart';

import 'package:achiver_app/screens/help_screen.dart';
import 'package:achiver_app/screens/edit_teacher_profile_page.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final TeacherProfileService _profileService = TeacherProfileService();
  final LeaveService _leaveService = LeaveService();
  File? _image;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? teacherData;
  bool isLoading = true;
  List<Map<String, dynamic>>? _leaveAppointments;

  // Sample teacher data - in a real app, this would come from a database
  // final Map<String, dynamic> teacherData = {
  //   'name': 'Mrs. Lakshmi',
  //   'subject': 'Mathematics',
  //   'experience': '15 years',
  //   'education': 'M.Sc., B.Ed.',
  //   'email': 'lakshmi@school.edu',
  //   'phone': '+91 9876543210',
  //   'classes': ['10-A', '9-B', '11-A'],
  //   'achievements': [
  //     'Best Teacher Award 2022',
  //     'Published 3 academic papers',
  //     'Mentored winning team in Math Olympiad'
  //   ]
  // };

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
    final imageUrl = await _profileService.getProfileImageUrl(teacherId);
    setState(() {
      teacherData = profile;
      _profileImageUrl = imageUrl;
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
          _leaveAppointments = appointments;
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

  Future<void> _pickImage() async {
    try {
      final String? teacherId = await AuthService.getUserId();
      if (teacherId == null) {
        throw 'Teacher not logged in';
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          isLoading = true;
        });

        // Upload the image
        final imageUrl = await _profileService.uploadProfileImage(_image!, teacherId);
        
        setState(() {
          _profileImageUrl = imageUrl;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: const Text(
          'Teacher Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  _buildClassesSection(),
                  const SizedBox(height: 20),
                  const SizedBox(height: 5),
                  _buildMenuSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String teacherName = teacherData?['name'] ?? 'Teacher';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null,
                      child: (_image == null && _profileImageUrl == null)
                          ? Icon(Icons.person,
                              size: 50, color: Colors.blue.shade300)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${teacherData?['name']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${teacherData?['subject']} • ${teacherData?['experience']} experience',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information', Icons.info_outline),
            const SizedBox(height: 16),
            _buildInfoItem(
                'Education',
                teacherData?['education']?.toString() ?? 'Not specified',
                Icons.school),
            _buildInfoItem(
                'Email',
                teacherData?['email']?.toString() ?? 'Not specified',
                Icons.email),
            _buildInfoItem(
                'Phone',
                teacherData?['phone']?.toString() ?? 'Not specified',
                Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesSection() {
    final classes = teacherData?['classes'] as List<dynamic>? ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Classes Teaching', Icons.class_),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue[700]),
                  onPressed: () => _showEditClassesDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (classes.isEmpty)
              const Text('No classes assigned',
                  style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  classes.length,
                  (index) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      classes[index].toString(),
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditClassesDialog(BuildContext context) {
    final classes = teacherData?['classes'] as List<dynamic>? ?? [];
    final TextEditingController classController = TextEditingController();

    // Convert the classes data to the correct format
    List<String> editedClasses = [];
    for (var classData in classes) {
      if (classData is String) {
        editedClasses.add(classData);
      } else if (classData is Map && classData['class'] != null) {
        editedClasses.add(classData['class'].toString());
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Classes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display existing classes
                if (editedClasses.isNotEmpty) ...[
                  const Text('Current Classes:'),
                  const SizedBox(height: 8),
                  ...editedClasses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final className = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Class $className'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                editedClasses.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                ],
                // Add new class form
                const Text('Add New Class:'),
                const SizedBox(height: 8),
                TextField(
                  controller: classController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    hintText: 'e.g., 10',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (classController.text.isNotEmpty) {
                      setState(() {
                        editedClasses.add(classController.text);
                        classController.clear();
                      });
                    }
                  },
                  child: const Text('Add Class'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final String? teacherId = await AuthService.getUserId();
                  if (teacherId == null) {
                    throw 'Teacher not logged in';
                  }

                  // Update classes in Firestore
                  await _profileService.updateTeacherClasses(
                    teacherId: teacherId,
                    classes: editedClasses,
                  );

                  // Refresh teacher profile
                  await fetchTeacherProfile();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Classes updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating classes: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem('Edit Profile', Icons.edit, onTap: () async {
          if (teacherData != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditTeacherProfilePage(
                  teacherData: teacherData!,
                ),
              ),
            );
            if (result != null) {
              setState(() {
                teacherData = result;
              });
            }
          }
        }),
        _buildMenuItem('Teaching Resources', Icons.book, onTap: () {
          // Navigate to teaching resources page
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherResourcesScreen(),
              ));
        }),
        _buildMenuItem('Help & Support', Icons.help_outline, onTap: () {
          // Navigate to help and support page
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpScreen(),
              ));
        }),
        const SizedBox(height: 10),
        _buildMenuItem(
          'Logout',
          Icons.logout,
          color: Colors.red,
          onTap: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to login screen
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Add this new method to show leave appointments dialog
  void _showLeaveAppointmentsDialog(BuildContext context) {
    // Sample leave appointment data - in a real app, this would come from a database
    final List<Map<String, dynamic>> leaveAppointments = [
      {
        'studentName': 'Rahul Kumar',
        'class': '8-A',
        'startDate': '15/05/2023',
        'endDate': '18/05/2023',
        'reason': 'Family function',
        'status': 'Pending'
      },
      {
        'studentName': 'Priya Sharma',
        'class': '10-A',
        'startDate': '20/05/2023',
        'endDate': '22/05/2023',
        'reason': 'Medical appointment',
        'status': 'Pending'
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_busy, color: Colors.blue[700], size: 24),
            const SizedBox(width: 8),
            const Text('Leave Appointments'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (leaveAppointments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No pending leave appointments',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...leaveAppointments.map(
                    (appointment) => _buildLeaveAppointmentTile(appointment)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveAppointmentTile(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            appointment['studentName'][0],
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          appointment['studentName'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Class ${appointment['class']} • ${appointment['startDate']} to ${appointment['endDate']}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            appointment['status'],
            style: TextStyle(
              color: Colors.orange.shade800,
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
                const SizedBox(height: 8),
                Text(
                  'Reason: ${appointment['reason']}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Handle rejection logic
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Handle approval logic
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value?.toString() ?? 'Not specified',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon,
      {VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 14,
            fontWeight: color != null ? FontWeight.w500 : null,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
      ),
    );
  }
}
