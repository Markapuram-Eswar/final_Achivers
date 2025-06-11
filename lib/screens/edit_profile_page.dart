import 'package:flutter/material.dart';
import '../services/student_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _studentService.getStudentProfile();
      if (mounted) {
        setState(() {
          _rollNoController.text = profile['rollNumber'] ?? '';
          _fullNameController.text = profile['name'] ?? '';
          _classController.text = profile['class'] ?? '';
          _sectionController.text = profile['section'] ?? '';
          _parentEmailController.text = profile['parentEmail'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _studentService.updateStudentProfile(
        name: _fullNameController.text.trim(),
        className: _classController.text.trim(),
        section: _sectionController.text.trim(),
        parentEmail: _parentEmailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _rollNoController.dispose();
    _fullNameController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Roll Number (non-editable)
                    TextFormField(
                      controller: _rollNoController,
                      decoration: InputDecoration(
                        labelText: 'Roll Number',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      readOnly: true,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Class
                    TextFormField(
                      controller: _classController,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your class';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section
                    TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your section';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Parent Email
                    TextFormField(
                      controller: _parentEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Parent Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter parent email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
