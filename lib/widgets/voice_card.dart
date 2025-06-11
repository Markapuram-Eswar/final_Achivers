import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final String? selectedVoiceType;
  final bool isPlaying;
  final Color themeColor;
  final Function(String) onPlayAudio;
  final Map<String, Map<String, dynamic>> voiceConfigs;

  const VoiceCard({
    super.key,
    required this.lesson,
    required this.selectedVoiceType,
    required this.isPlaying,
    required this.themeColor,
    required this.onPlayAudio,
    required this.voiceConfigs,
  });

  String? getCurrentAudioUrl() {
    if (selectedVoiceType == null) return null;
    return lesson['audio_$selectedVoiceType'];
  }

  @override
  Widget build(BuildContext context) {
    final currentAudioUrl = getCurrentAudioUrl();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lesson Image
          if (lesson['image'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                lesson['image'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.red, size: 40),
                ),
              ),
            ),

          // Lesson Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lesson['heading'] ?? 'Lesson',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (currentAudioUrl != null)
                      IconButton(
                        onPressed: () => onPlayAudio(currentAudioUrl),
                        icon: Icon(
                          isPlaying ? Icons.stop_circle : Icons.play_circle,
                          size: 40,
                          color: isPlaying ? Colors.red : themeColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lesson['paragraph'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }
}