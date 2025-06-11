import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  bool _isLoading = false;
  int _selectedRole = 0; // 0: Student, 1: Teacher, 2: Parent

  Widget _buildRoleRadio(int index, String title) {
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

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
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

  String _getIdFieldLabel() {
    switch (_selectedRole) {
      case 0:
        return 'Roll Number';
      case 1:
        return 'Employee ID';
      case 2:
        return "Child's Roll Number";
      default:
        return 'ID';
    }
  }

  String? _validateId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${_getIdFieldLabel().toLowerCase()}';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();

      switch (_selectedRole) {
        case 0: // Student
          /* Backend TODO: Authenticate student login (API call, session/token management) */
          await authService.loginStudent(_idController.text.trim());
          // Save roll number for doubts page
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'student_roll_number', _idController.text.trim());
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/welcome_page');
          }
          break;

        case 1: // Teacher
          /* Backend TODO: Authenticate teacher login (API call, session/token management) */
          await authService.loginTeacher(_idController.text.trim());
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/teacher-dashboard');
            print(mounted);
          }
          break;

        case 2: // Parent
          /* Backend TODO: Authenticate parent login (API call, session/token management) */
          await authService.loginParent(_idController.text.trim());
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/parent-dashboard');
          }
          break;

        default:
          throw 'Invalid role selected';
      }

      Fluttertoast.showToast(msg: 'Logged in as [1m${_getRoleName()}');
    } catch (e) {
      /* Backend TODO: Handle login error responses from backend */
      Fluttertoast.showToast(
        msg: 'Login failed: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Set the orientation to portrait only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.4,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 18),
                // Login As
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login As',
                      style: TextStyle(fontSize: 15, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRoleRadio(0, 'Student'),
                          const SizedBox(width: 8),
                          _buildRoleRadio(1, 'Teacher'),
                          const SizedBox(width: 8),
                          _buildRoleRadio(2, 'Parent'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card-like login form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // ID Field
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _idController,
                                decoration: InputDecoration(
                                  hintText: 'Enter ${_getIdFieldLabel()}',
                                  border: const UnderlineInputBorder(),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: _validateId,
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB547),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
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
                                    'Login as ${_getRoleName()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFFB547),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
