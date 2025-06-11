import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/teacher_contact_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactTeacherScreen extends StatefulWidget {
  final bool showExitConfirmation;
  final Widget? previousScreen;
  final bool isFromHomePage;

  const ContactTeacherScreen({
    super.key,
    this.showExitConfirmation = false,
    this.previousScreen,
    this.isFromHomePage = false,
  });

  @override
  State<ContactTeacherScreen> createState() => _ContactTeacherScreenState();
}

class _ContactTeacherScreenState extends State<ContactTeacherScreen> {
  final TeacherContactService _teacherService = TeacherContactService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> teachers = [];
  bool isLoading = true;
  String? error;
  String? studentClass;
  List<String> parentClasses = [];
  String? userType;
  String? parentPhone;

  @override
  void initState() {
    super.initState();
    _loadUserAndTeachers();
  }

  Future<void> _loadUserAndTeachers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      userType = await AuthService.getUserType();
      final String? userId = await AuthService.getUserId();
      if (userType == null || userId == null) {
        throw 'User not logged in';
      }

      String? className;
      List<String> classList = [];
      String? phone;

      if (userType == 'parent') {
        // Fetch parent document
        final parentDoc =
            await _firestore.collection('parents').doc(userId).get();
        if (!parentDoc.exists) {
          throw 'Parent profile not found';
        }
        final parentData = parentDoc.data() as Map<String, dynamic>;
        // Parent can have multiple classes
        final parentClassList =
            (parentData['class'] as List?)?.map((e) => e.toString()).toList() ??
                [];
        classList = parentClassList;
        parentClasses = classList;
        parentPhone = parentData['phone']?.toString();
      } else {
        // Student logic (as before)
        final studentDoc =
            await _firestore.collection('students').doc(userId).get();
        if (!studentDoc.exists) {
          throw 'Student profile not found';
        }
        final studentData = studentDoc.data() as Map<String, dynamic>;
        className = studentData['class']?.toString();
        if (className == null) {
          throw 'Student class information not found';
        }
        studentClass = className;
        classList = [className];
      }

      // Get all teachers
      final QuerySnapshot teacherSnapshot =
          await _firestore.collection('teachers').get();
      final List<Map<String, dynamic>> teacherList = [];
      for (final doc in teacherSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final teacherClasses =
            (data['classes'] as List?)?.map((e) => e.toString()).toList() ?? [];
        // If teacher teaches any of the user's classes, include
        bool teachesRelevantClass =
            classList.any((c) => teacherClasses.contains(c));
        if (teachesRelevantClass) {
          teacherList.add({
            'name': data['name'] ?? '',
            'subject': data['subject'] ?? '',
            'phone': data['phone'] ?? '',
            'image': (data['name'] ?? '').isNotEmpty ? data['name'][0] : '',
            'classes': teacherClasses,
          });
        }
      }

      setState(() {
        teachers = teacherList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading teachers: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.isFromHomePage) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App?'),
              content: const Text('Do you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        } else if (widget.previousScreen != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget.previousScreen!),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isFromHomePage,
          backgroundColor: Colors.blue[900],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Teachers',
                style: TextStyle(color: Colors.white),
              ),
              if (userType == 'parent' && parentClasses.isNotEmpty)
                Text(
                  'Classes: ${parentClasses.join(', ')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              if (userType == 'student' && studentClass != null)
                Text(
                  'Class: $studentClass',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUserAndTeachers,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserAndTeachers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No teachers found for your class',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (userType == 'parent' && parentClasses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Classes: ${parentClasses.join(', ')}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (userType == 'student' && studentClass != null) ...[
              const SizedBox(height: 8),
              Text(
                'Class: $studentClass',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 30,
              child: Text(
                teacher['image'],
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              teacher['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(teacher['subject']),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildContactButton(
                    icon: Icons.connect_without_contact,
                    label: 'WhatsApp',
                    backgroundColor: const Color(0xFF25D366),
                    onPressed: () async {
                      String phoneNumber = userType == 'parent' &&
                              parentPhone != null &&
                              parentPhone!.isNotEmpty
                          ? parentPhone!
                          : teacher['phone'];
                      if (phoneNumber.startsWith('+')) {
                        phoneNumber = phoneNumber.substring(1);
                      }
                      final message =
                          'Hello ${teacher['name']}, I would like to connect with you regarding ${teacher['subject']}.';
                      final whatsappUrl =
                          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
                      await launchUrlString(
                        whatsappUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton.icon(
      icon: const FaIcon(FontAwesomeIcons.whatsapp,
          size: 26, color: Colors.white),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 52),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    );
  }
}
