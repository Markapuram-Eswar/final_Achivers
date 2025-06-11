import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const MaterialApp(
      home: STTKeywordMatcher(subjectData: {}, topicData: {})));
}

class Question {
  final String text;
  final List<String> keywords;
  final String note;

  Question({
    required this.text,
    required this.keywords,
    required this.note,
  });
}

class STTKeywordMatcher extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> topicData;

  const STTKeywordMatcher({
    super.key,
    required this.subjectData,
    required this.topicData,
  });

  @override
  State<STTKeywordMatcher> createState() => _STTKeywordMatcherState();
}

class _STTKeywordMatcherState extends State<STTKeywordMatcher> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _paragraph = '';
  String _selectedLanguage = 'en-US';
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  final Map<String, String> _languages = {
    'English': 'en-US',
    'Telugu': 'te-IN',
    'Hindi': 'hi-IN',
    'Tamil': 'ta-IN',
    'Malayalam': 'ml-IN',
    'Kannada': 'kn-IN',
  };

  List<Question> get questions {
    // If topicData contains a questions list, use only vocal questions
    final dynamic allQuestions = widget.topicData['questions'];
    if (allQuestions is List && allQuestions.isNotEmpty) {
      final vocalQuestions = allQuestions
          .where((q) => (q['type'] ?? '').toString().toLowerCase() == 'vocal')
          .toList();
      if (vocalQuestions.isNotEmpty) {
        return vocalQuestions
            .map<Question>((q) => Question(
                  text: q['question'] ?? 'Untitled',
                  keywords: List<String>.from(q['keywords'] ?? []),
                  note: q['note'] ?? '',
                ))
            .toList();
      }
    }
    // fallback to demo
    return [
      Question(
        text: 'Explain photosynthesis.',
        keywords: [
          'photosynthesis',
          'sunlight',
          'carbon dioxide',
          'plants',
          'leaves',
          'oxygen',
          'ఫోటోసింథసిస్',
          'సూర్యరశ్మి',
          'కార్బన్ డయాక్సైడ్',
          'చెట్లు',
          'ఆకు',
          'ఆక్సిజన్',
          'प्रकाश संश्लेषण',
          'सूरज की रोशनी',
          'कार्बन डाइऑक्साइड',
          'पौधे',
          'पत्ते',
          'ऑक्सीजन',
        ],
        note: 'Hint: Think about sunlight, plants, and oxygen.',
      ),
      Question(
        text: 'Describe the water cycle.',
        keywords: [
          'evaporation',
          'condensation',
          'precipitation',
          'water vapor',
          'clouds',
          'rain',
          'వేసవి ఆవిరి',
          'మేఘాలు',
          'వర్షం',
          'वाष्पीकरण',
          'संघनन',
          'वृष्टि',
        ],
        note: 'Remember evaporation, condensation, precipitation.',
      ),
    ];
  }

  int _selectedQuestionIndex = 0;
  List<String> matchedKeywords = [];
  List<String> missedKeywords = [];
  double matchPercentage = 0.0;

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _paragraph = '';
        matchedKeywords = [];
        missedKeywords = [];
        matchPercentage = 0.0;
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _paragraph = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        localeId: _selectedLanguage,
      );
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    matchKeywords(_paragraph, questions[_selectedQuestionIndex].keywords);
  }

  void matchKeywords(String input, List<String> keywords) {
    final lowerInput = input.toLowerCase();
    final matched = <String>[];
    final missed = <String>[];

    for (final keyword in keywords) {
      if (lowerInput.contains(keyword.toLowerCase())) {
        matched.add(keyword);
      } else {
        missed.add(keyword);
      }
    }

    final percentage =
        keywords.isNotEmpty ? (matched.length / keywords.length) * 100 : 0.0;

    setState(() {
      matchedKeywords = matched;
      missedKeywords = missed;
      matchPercentage = percentage;
    });

    if (percentage >= 70) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[_selectedQuestionIndex];

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[100]!,
                  Colors.purple[50]!,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Speech Learning',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ).animate().fadeIn().slideX(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question selector card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Question:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _selectedQuestionIndex,
                              items: List.generate(
                                questions.length,
                                (index) => DropdownMenuItem(
                                  value: index,
                                  child: Text(
                                    questions[index].text,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedQuestionIndex = value;
                                    _paragraph = '';
                                    matchedKeywords = [];
                                    missedKeywords = [];
                                    matchPercentage = 0.0;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(),

                    const SizedBox(height: 16),

                    // Hint card
                    Card(
                      elevation: 4,
                      color: Colors.amber[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currentQuestion.note,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(delay: 200.ms),

                    const SizedBox(height: 16),

                    // Language selector
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Language:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _selectedLanguage,
                              items: _languages.entries
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.value,
                                      child: Text(
                                        entry.key,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedLanguage = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(delay: 400.ms),

                    const SizedBox(height: 16),

                    // Speech recognition area
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: SingleChildScrollView(
                                child: Text(
                                  _paragraph.isEmpty
                                      ? 'Start speaking...'
                                      : _paragraph,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: _paragraph.isEmpty
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            if (_isListening)
                              Positioned(
                                right: 16,
                                top: 16,
                                child: Lottie.network(
                                  'https://assets2.lottiefiles.com/packages/lf20_oCue1F.json',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(delay: 600.ms),

                    const SizedBox(height: 16),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isListening ? _stopListening : _startListening,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isListening ? Colors.red : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isListening ? Icons.stop : Icons.mic),
                            const SizedBox(width: 8),
                            Text(
                              _isListening
                                  ? 'Stop Recording'
                                  : 'Start Speaking',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(delay: 800.ms),

                    if (matchedKeywords.isNotEmpty ||
                        missedKeywords.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Score: ${matchPercentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: matchPercentage >= 70
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (matchedKeywords.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: matchedKeywords
                                      .map(
                                        (keyword) => Chip(
                                          label: Text(
                                            keyword,
                                            style: GoogleFonts.poppins(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      )
                                      .toList(),
                                ),
                              if (missedKeywords.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: missedKeywords
                                      .map(
                                        (keyword) => Chip(
                                          label: Text(
                                            keyword,
                                            style: GoogleFonts.poppins(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red[300],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn().slideY(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
