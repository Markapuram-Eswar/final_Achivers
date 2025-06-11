import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_page.dart';

class ThemeSplashScreen extends StatefulWidget {
  final String selectedTheme;
  final VoidCallback? onThemeToggle;

  const ThemeSplashScreen({
    super.key,
    required this.selectedTheme,
    this.onThemeToggle,
  });

  @override
  State<ThemeSplashScreen> createState() => _ThemeSplashScreenState();
}

class _ThemeSplashScreenState extends State<ThemeSplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    /* Backend TODO: Check user session and fetch theme splash data from backend (API call, session management) */
    _initializeVideo();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(
            selectedTheme: widget.selectedTheme,
            onThemeToggle: widget.onThemeToggle,
          ),
        ),
      );
    });
  }

  void _initializeVideo() {
    String videoAsset;
    switch (widget.selectedTheme) {
      case 'STUDENT DISPLAY':
        videoAsset = 'assets/videos/student_theme.mp4';
        break;
      case 'Park Display':
        videoAsset = 'assets/videos/park_theme.mp4';
        break;
      case 'Game Display':
        videoAsset = 'assets/videos/game_theme.mp4';
        break;
      default:
        videoAsset = 'assets/videos/student_theme.mp4';
    }

    _videoController = VideoPlayerController.asset(videoAsset)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isVideoInitialized = true);
          _videoController
            ..setLooping(true)
            ..setVolume(0.0)
            ..play();
        }
      }).catchError((e) {
        if (kDebugMode) {
          print("Video error: $e");
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator()), // Only shows while loading
    );
  }
}
