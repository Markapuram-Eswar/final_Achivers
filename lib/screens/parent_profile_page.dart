import 'package:achiver_app/screens/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/parent_service.dart';
import 'edit_parent_profile_page.dart';

void main() {
  runApp(const MaterialApp(
    home: ParentProfilePage(),
  ));
}

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  final ParentService _parentService = ParentService();
  File? _image;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  Map<String, dynamic>? _parentData;

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      final parentData = await _parentService.getParentProfile();
      final imageUrl = await _parentService.getProfileImageUrl();
      if (mounted) {
        setState(() {
          _parentData = parentData;
          _profileImageUrl = imageUrl;
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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true;
        });

        // Upload the image
        final imageUrl = await _parentService.uploadProfileImage(_image!);
        
        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          elevation: 0,
          title: const Text(
            'Parent Profile',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_parentData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          elevation: 0,
          title: const Text(
            'Parent Profile',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Failed to load profile data'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: const Text(
          'Parent Profile',
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
            _parentData!['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Parent',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
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
            _buildSectionHeader('Contact Information', Icons.contact_page),
            const SizedBox(height: 16),
            _buildInfoItem(
                'Phone', _parentData!['phone'] ?? 'N/A', Icons.phone),
            if (_parentData!['email'] != null)
              _buildInfoItem('Email', _parentData!['email'], Icons.email),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenSection() {
    final children = _parentData!['children'] as List<Map<String, dynamic>>;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Children', Icons.child_care),
            const SizedBox(height: 16),
            ...children.map<Widget>((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Class ${child['class']} - Section ${child['section']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditParentProfilePage(),
            ),
          );
          if (result != null) {
            setState(() {
              _parentData = result;
            });
          }
        }),
        _buildMenuItem('Help', Icons.help_outline, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
        }),
        const SizedBox(height: 10),
        _buildMenuItem('Logout', Icons.logout, color: Colors.red, onTap: () {
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
                      /* Backend TODO: Clear user session and tokens on logout */
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
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
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
            color: color?.withValues(alpha: 0.1) ?? Colors.blue.shade50,
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

extension _ChangePasswordDialog on _ParentProfilePageState {
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool showCurrent = false;
        bool showNew = false;
        bool showConfirm = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.lock_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Change Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !showCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(showCurrent
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => showCurrent = !showCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: !showNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            showNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => showNew = !showNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(showConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => showConfirm = !showConfirm),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText ?? 'error',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Change Password'),
                onPressed: () {
                  setState(() => errorText = null);
                  if (currentPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    setState(() => errorText = 'Please fill all fields');
                    return;
                  }
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    setState(() => errorText = 'New passwords do not match');
                    return;
                  }
                  // TODO: Implement password change with backend
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password changed successfully')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

extension _NotificationSettingsDialog on _ParentProfilePageState {
  void _showNotificationSettingsDialog() {
    bool appNotifications = true;
    bool emailNotifications = false;
    bool smsNotifications = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Notification Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('App Notifications'),
                  value: appNotifications,
                  onChanged: (val) => setState(() => appNotifications = val),
                ),
                // SwitchListTile(
                //   title: const Text('Email Notifications'),
                //   value: emailNotifications,
                //   onChanged: (val) => setState(() => emailNotifications = val),
                // ),
                // SwitchListTile(
                //   title: const Text('SMS Notifications'),
                //   value: smsNotifications,
                //   onChanged: (val) => setState(() => smsNotifications = val),
                // ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  // TODO: Save settings to backend or local storage
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
