import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/registration_service.dart';
import 'login_page.dart';
import 'payment_screen.dart';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _selectedRole = 0; // 0: Student, 1: Teacher, 2: Parent
  bool _isLoading = false;

  // Form controllers - common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Student specific
  final _rollNumberController = TextEditingController();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();

  // Teacher specific
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();

  // Parent specific
  final _childRollNumberController = TextEditingController();

  // FCM Tokens
  Future<String> _generateFCMToken(String type) async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    // Get the token
    String? token = await _firebaseMessaging.getToken();

    if (token == null) {
      throw Exception('Failed to get FCM token');
    }

    // Add prefix based on type
    return type == 'student' ? '$token' : '$token';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _rollNumberController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _childRollNumberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final registrationService = RegistrationService();

      if (_selectedRole == 0) {
        // Student
        // Show payment screen first
        // final paymentResult = await Navigator.push<bool>(
        //   context,
        //   MaterialPageRoute(builder: (context) => const PaymentScreen()),
        // );

        // if (paymentResult != true) {
        //   setState(() => _isLoading = false);
        //   return;
        // }

        // Generate student FCM token
        final studentFCMToken = await _generateFCMToken('student');

        // Register student
        await registrationService.registerStudent(
          rollNumber: _rollNumberController.text.trim(),
          name: _nameController.text.trim(),
          className: _classController.text.trim(),
          section: _sectionController.text.trim(),
          parentEmail: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          studentFCMToken: studentFCMToken,
        );
      } else {
        // Parent
        // Generate parent FCM token
        final parentFCMToken = await _generateFCMToken('parent');

        // Register parent
        await registrationService.registerParent(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          childRollNumber: _childRollNumberController.text.trim(),
          parentFCMToken: parentFCMToken,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRoleName() {
    switch (_selectedRole) {
      case 0:
        return 'Student';
      case 1:
        return 'Teacher';
      case 2:
        return 'Parent';
      default:
        return '';
    }
  }

  Widget _buildStudentForm() {
    return Column(
      children: [
        _buildTextField('Roll Number',
            controller: _rollNumberController, isRequired: true),
        _buildTextField('Full Name',
            controller: _nameController, isRequired: true),
        _buildTextField('Class',
            controller: _classController, isRequired: true),
        _buildTextField('Section',
            controller: _sectionController, isRequired: true),
        _buildTextField('Parent Email (optional)',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildParentForm() {
    return Column(
      children: [
        _buildTextField("Child's Roll Number",
            controller: _childRollNumberController, isRequired: true),
        _buildTextField('Your Full Name',
            controller: _nameController, isRequired: true),
        _buildTextField('Phone Number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            isRequired: true),
        _buildTextField('Email (optional)',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildForm() {
    switch (_selectedRole) {
      case 0: // Student
        return _buildStudentForm();
      case 2: // Parent
        return _buildParentForm();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Let's Get Started!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Register As
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Register As',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      _buildRoleSelection(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dynamic form based on role
                  _buildForm(),

                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB547),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Register as ${_getRoleName()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginPage()),
                                );
                              },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFFB547),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildRoleSelection() {
    return Row(
      children: [
        _buildRoleRadio(0, 'Student'),
        const SizedBox(width: 8),
        _buildRoleRadio(2, 'Parent'),
      ],
    );
  }

  Widget _buildRoleRadio(int index, String title) {
    // Skip Teacher role (index 1)
    if (index == 1) return const SizedBox.shrink();

    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          color: _selectedRole == index ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: _selectedRole == index,
      selectedColor: const Color(0xFFFFB547),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedRole = index;
        });
      },
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: const UnderlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          if (keyboardType == TextInputType.emailAddress &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          if (keyboardType == TextInputType.phone &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
      ),
    );
  }
}
