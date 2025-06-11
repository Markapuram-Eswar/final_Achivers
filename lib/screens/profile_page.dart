import 'package:achiver_app/screens/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'videos_screen.dart';
import 'tts.dart';
import 'edit_profile_page.dart';
import '../services/ProfileService.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  File? _image;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await _profileService.getStudentProfile();
      final imageUrl = await _profileService.getProfileImageUrl();
      setState(() {
        studentData = data;
        _profileImageUrl = imageUrl;
        isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
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
        final imageUrl = await _profileService.uploadProfileImage(_image!);
        
        setState(() {
          _profileImageUrl = imageUrl;
          isLoading = false;
        });

        Fluttertoast.showToast(msg: 'Profile image updated successfully');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Failed to update profile image: $e');
    }
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon,
      {Color color = Colors.black87, required VoidCallback onTap}) {
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
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final fullName = studentData?['fullName'] ?? 'Eswar Kumar';
    final name = studentData?['name'] ?? 'Eswar Kumar';
    final rollNumber = studentData?['rollNumber'] ?? '22CS123';
    final studentClass = studentData?['class'] ?? '10th';
    final section = studentData?['section'] ?? 'A';
    final parentEmail =
        studentData?['parentEmail'] ?? 'No parent email provided';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                              border: Border.all(
                                  color: Colors.blue.shade100, width: 3),
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
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileInfoRow('Roll Number', rollNumber),
                        const Divider(height: 20),
                        _buildProfileInfoRow('Name', name),
                        const Divider(height: 20),
                        _buildProfileInfoRow(
                            'Class & Section', '$studentClass - $section'),
                        const Divider(height: 20),
                        _buildProfileInfoRow("Parent's Email", parentEmail),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildMenuItem('Edit Account', Icons.edit, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()),
                    ).then((_) {
                      // Call your method to refresh the parent widget here
                      setState(() {
                        fetchProfile(); // Or any method that reloads the data
                      });
                    });
                  }),
                  _buildMenuItem('Help', Icons.help_outline, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpScreen()),
                    );
                  }),
                  // _buildMenuItem('Text to Speech', Icons.volume_up, onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => const SimpleReadingTracker()),
                  //   );
                  // }),
                  // _buildMenuItem('Videos', Icons.video_library, onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => VideoFlowScreen(
                  //               subjectData: {},
                  //               topicData: {},
                  //             )),
                  //   );
                  // }),
                  const SizedBox(height: 20),
                  _buildMenuItem('Logout', Icons.logout, color: Colors.red,
                      onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
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
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
