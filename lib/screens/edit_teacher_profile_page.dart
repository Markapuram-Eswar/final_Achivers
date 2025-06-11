import 'package:flutter/material.dart';
import '../services/teacher_profile_service.dart';
import '../services/auth_service.dart';

class EditTeacherProfilePage extends StatefulWidget {
  final Map<String, dynamic> teacherData;

  const EditTeacherProfilePage({
    super.key,
    required this.teacherData,
  });

  @override
  State<EditTeacherProfilePage> createState() => _EditTeacherProfilePageState();
}

class _EditTeacherProfilePageState extends State<EditTeacherProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TeacherProfileService _profileService = TeacherProfileService();
  bool _isLoading = false;

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.teacherData['name']);
    _subjectController = TextEditingController(text: widget.teacherData['subject']);
    _experienceController = TextEditingController(text: widget.teacherData['experience']);
    _educationController = TextEditingController(text: widget.teacherData['education']);
    _emailController = TextEditingController(text: widget.teacherData['email']);
    _phoneController = TextEditingController(text: widget.teacherData['phone']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String? teacherId = await AuthService.getUserId();
      if (teacherId == null) throw 'Teacher not logged in';

      final updatedData = {
        'name': _nameController.text,
        'subject': _subjectController.text,
        'experience': _experienceController.text,
        'education': _educationController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      await _profileService.updateTeacherProfile(
        teacherId: teacherId,
        profileData: updatedData,
      );

      if (mounted) {
        Navigator.pop(context, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Subject',
                      controller: _subjectController,
                      icon: Icons.book,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Experience',
                      controller: _experienceController,
                      icon: Icons.work,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your experience';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Education',
                      controller: _educationController,
                      icon: Icons.school,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your education';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      label: 'Phone',
                      controller: _phoneController,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[700]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
} 