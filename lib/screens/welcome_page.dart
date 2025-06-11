import 'package:flutter/material.dart';
import 'theme_splash_screen.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const WelcomePage({super.key, this.onThemeToggle});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String _selectedTheme = 'STUDENT DISPLAY';

  LinearGradient _getThemeGradient() {
    switch (_selectedTheme) {
      case 'STUDENT DISPLAY':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FA), Colors.white],
        );
      case 'Park Display':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81C784), Color(0xFFA5D6A7)],
        );
      case 'Game Display':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FA), Colors.white],
        );
    }
  }

  Color _getThemeColor() {
    switch (_selectedTheme) {
      case 'STUDENT DISPLAY':
        return Colors.blue;
      case 'Park Display':
        return Colors.green;
      case 'Game Display':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  @override
  void initState() {
    super.initState();
    /* Backend TODO: Fetch welcome page user data from backend (API call, database read) */
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getThemeGradient(),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Image.network(
                    'https://img.icons8.com/isometric/50/minecraft-logo.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Welcome to Achievers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getThemeColor(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your journey to success starts here',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getThemeColor().withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getThemeColor(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            'STUDENT DISPLAY',
                            'Park Display',
                            'Game Display'
                          ].map((theme) {
                            final isSelected = _selectedTheme == theme;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: SizedBox(
                                width: double.infinity,
                                height:
                                    60, // Increase height for better touch target
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTheme = theme;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? _getThemeColor()
                                        : Colors.white,
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : _getThemeColor(),
                                    side: BorderSide(color: _getThemeColor()),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20), // Increased padding
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    theme,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18, // Increased font size
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 60, // Increased from 50 to 60
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedTheme.isNotEmpty) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThemeSplashScreen(
                                selectedTheme: _selectedTheme,
                                onThemeToggle: widget.onThemeToggle,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getThemeColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Add padding to make button content larger
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 20, // Increased from 18 to 20
                          fontWeight: FontWeight.bold, // Added bold
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
