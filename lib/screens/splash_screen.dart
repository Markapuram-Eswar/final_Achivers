import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    /* Backend TODO: Check user session and fetch splash data from backend (API call, session management) */

    // Check if user is already logged in
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      final userType = await AuthService.getUserType();
      if (!mounted) return;

      // Navigate to the appropriate dashboard based on user type
      switch (userType) {
        case 'student':
          Navigator.pushReplacementNamed(context, '/welcome_page');
          break;
        case 'teacher':
          Navigator.pushReplacementNamed(context, '/teacher-dashboard');
          break;
        case 'parent':
          Navigator.pushReplacementNamed(context, '/parent-dashboard');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // No user logged in, go to login page
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFd3e5ff), // light blue top left
              Color(0xFFb7ccf7), // slightly deeper blue bottom right
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF6E3),
                      borderRadius: BorderRadius.circular(32),
                      border:
                          Border.all(color: const Color(0xFFD4B97F), width: 2),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error,
                            size: 100, color: Colors.red);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
