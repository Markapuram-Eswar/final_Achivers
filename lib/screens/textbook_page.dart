import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/textbook_service.dart';
import '../widgets/voice_card.dart';

class TextBookApp extends StatelessWidget {
  final String subject;
  final String classNumber;
  final String topic;

  const TextBookApp({
    super.key,
    required this.subject,
    required this.classNumber,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: TextBookAudioPage(
        subjectData: {
          'title': subject,
          'color': Colors.blue,
        },
        topicData: {
          'title': topic,
          'image': 'https://picsum.photos/800/400',
          'lessons': [
            {
              'heading': 'பாடம் 1 - Tamil',
              'paragraph': 'நான் தினமும் பள்ளிக்கு செல்கிறேன் என் நண்பர்களுடன்',
              'imageUrl': 'https://picsum.photos/800/400?random=1',
              'audio_kidmale': 'https://example.com/tamil_kidmale.mp3',
              'audio_kidfemale': 'https://example.com/tamil_kidfemale.mp3',
              'audio_male': 'https://example.com/tamil_male.mp3',
              'audio_female': 'https://example.com/tamil_female.mp3',
            },
            {
              'heading': 'పాఠం 1 - Telugu',
              'paragraph': 'నేను ప్రతిరోజూ స్కూలుకి వెళ్తాను నా స్నేహితులతో',
              'imageUrl': 'https://picsum.photos/800/400?random=2',
              'audio_kidmale': 'https://example.com/telugu_kidmale.mp3',
              'audio_kidfemale': 'https://example.com/telugu_kidfemale.mp3',
              'audio_male': 'https://example.com/telugu_male.mp3',
              'audio_female': 'https://example.com/telugu_female.mp3',
            },
            {
              'heading': 'Lesson 1 - English',
              'paragraph': 'I go to school every day with my friends',
              'imageUrl': 'https://picsum.photos/800/400?random=3',
              'audio_kidmale': 'https://example.com/english_kidmale.mp3',
              'audio_kidfemale': 'https://example.com/english_kidfemale.mp3',
              'audio_male': 'https://example.com/english_male.mp3',
              'audio_female': 'https://example.com/english_female.mp3',
            },
          ],
        },
      ),
    );
  }
}

class TextBookAudioPage extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> topicData;

  const TextBookAudioPage({
    super.key,
    required this.subjectData,
    required this.topicData,
  });

  @override
  State<TextBookAudioPage> createState() => _TextBookAudioPageState();
}

class _TextBookAudioPageState extends State<TextBookAudioPage> {
  final TextbookService _textbookService = TextbookService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedVoiceType;
  bool _isPlaying = false;
  int? _currentlyPlayingIndex;
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = true;
  String? _error;

  // Voice type configurations
  final Map<String, Map<String, dynamic>> voiceConfigs = {
    'kidmale': {
      'label': 'Kid Male',
      'icon': Icons.boy,
      'color': Colors.blue,
    },
    'kidfemale': {
      'label': 'Kid Female',
      'icon': Icons.girl,
      'color': Colors.pink,
    },
    'male': {
      'label': 'Male',
      'icon': Icons.man,
      'color': Colors.green,
    },
    'female': {
      'label': 'Female',
      'icon': Icons.woman,
      'color': Colors.purple,
    },
  };

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _loadLessons();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingIndex = null;
          });
        }
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentlyPlayingIndex = null;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Subscribe to real-time updates
      _textbookService
          .streamTextbookContent(
        classNumber: widget.topicData['class'] ?? '6',
        subject: widget.subjectData['title'] ?? '',
        topic: widget.topicData['title'] ?? '',
      )
          .listen(
        (lessons) {
          if (mounted) {
            setState(() {
              _lessons = lessons;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> playAudio(String audioUrl, int index) async {
    try {
      // If the same card is clicked and is currently playing, stop it
      if (_isPlaying && _currentlyPlayingIndex == index) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentlyPlayingIndex = null;
        });
        return;
      }

      // If a different card is clicked, stop current playback and start new one
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      setState(() {
        _isPlaying = true;
        _currentlyPlayingIndex = index;
      });

      await _audioPlayer.setSourceUrl(audioUrl);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.subjectData['color'] as Color? ?? Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicData['title'] ?? ''),
        backgroundColor: color,
      ),
      body: Column(
        children: [
          // Voice Selection Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Voice',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildVoiceChip('Kid Male', 'kidmale', color),
                      const SizedBox(width: 8),
                      _buildVoiceChip('Kid Female', 'kidfemale', color),
                      const SizedBox(width: 8),
                      _buildVoiceChip('Male', 'male', color),
                      const SizedBox(width: 8),
                      _buildVoiceChip('Female', 'female', color),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lessons List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadLessons,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return VoiceCard(
                            lesson: lesson,
                            selectedVoiceType: _selectedVoiceType,
                            isPlaying:
                                _isPlaying && _currentlyPlayingIndex == index,
                            themeColor: color,
                            onPlayAudio: (url) => playAudio(url, index),
                            voiceConfigs: const {
                              'kidmale': {
                                'icon': Icons.child_care,
                                'label': 'Kid Male',
                              },
                              'kidfemale': {
                                'icon': Icons.child_care,
                                'label': 'Kid Female',
                              },
                              'male': {
                                'icon': Icons.person,
                                'label': 'Male',
                              },
                              'female': {
                                'icon': Icons.person,
                                'label': 'Female',
                              },
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceChip(String label, String value, Color color) {
    final isSelected = _selectedVoiceType == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : color,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedVoiceType = value;
          });
        }
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
