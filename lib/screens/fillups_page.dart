import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fillups_post_service.dart';
import '../services/auth_service.dart';

class FillupsPage extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> topicData;

  const FillupsPage({
    super.key,
    required this.subjectData,
    required this.topicData,
  });

  @override
  FillupsPageState createState() => FillupsPageState();
}

class FillupsPageState extends State<FillupsPage>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];

  final TextEditingController _answerController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  int _timeRemaining = 900; // 15 minutes in seconds
  int _score = 120;
  String _selectedAnswer = '';
  InputMode _currentInputMode = InputMode.text;
  List<String> _selectedLetters = [];
  List<String> _availableLetters = [];
  bool _showFeedback = false;
  bool _isCorrect = false;
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackAnimation;

  // Firebase and progress tracking
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  bool _isSubmittingProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _totalQuestions = _questions.length;
    _startTimer();
    _initializeSpeech();
    _shuffleLetters();
    _initializeAnimations();
  }

  void _initializeQuestions() {
    // Get questions from widget.topicData
    final allQuestions = widget.topicData['questions'];
    if (allQuestions != null && allQuestions is List) {
      _questions = allQuestions
          .where(
              (q) => (q['type'] ?? '').toString().toLowerCase() == 'fillblanks')
          .map<Map<String, dynamic>>((question) {
        final questionMap = Map<String, dynamic>.from(question);
        String answer = questionMap['answer']?.toString() ?? '';
        List<String> jumbledLetters = (questionMap['jumbledLetters'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            answer.toUpperCase().split('');
        return {
          'question': questionMap['question'] ?? '',
          'answer': answer,
          'hint': questionMap['hint'] ?? 'Think carefully about the answer',
          'jumbledLetters': jumbledLetters,
        };
      }).toList();
    }
    // Fallback to default questions if no data found
    if (_questions.isEmpty) {
      _questions = [
        {
          'question': 'What is the capital of France?',
          'answer': 'Paris',
          'hint': 'Think of the Eiffel Tower',
          'jumbledLetters': ['P', 'A', 'R', 'I', 'S'],
        },
        {
          'question': 'Which planet is known as the Red Planet?',
          'answer': 'Mars',
          'hint': 'Named after the Roman god of war',
          'jumbledLetters': ['M', 'A', 'R', 'S'],
        },
        {
          'question': 'What is the largest ocean on Earth?',
          'answer': 'Pacific',
          'hint': 'Means peaceful in Latin',
          'jumbledLetters': ['P', 'A', 'C', 'I', 'F', 'I', 'C'],
        },
        {
          'question': 'Which element has the symbol Au?',
          'answer': 'Gold',
          'hint': 'A precious metal',
          'jumbledLetters': ['G', 'O', 'L', 'D'],
        },
        {
          'question': 'What is the hardest natural substance?',
          'answer': 'Diamond',
          'hint': 'Made of pure carbon',
          'jumbledLetters': ['D', 'I', 'A', 'M', 'O', 'N', 'D'],
        },
      ];
    }
  }

  void _initializeAnimations() {
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        _startTimer();
      }
    });
  }

  Future<void> _initializeSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _speech.initialize();
    }
  }

  void _shuffleLetters() {
    if (_currentQuestionIndex < _questions.length) {
      _availableLetters =
          List.from(_questions[_currentQuestionIndex]['jumbledLetters']);
      _availableLetters.shuffle();
      _selectedLetters = [];
    }
  }

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetters.add(letter);
      _availableLetters.remove(letter);
      _selectedAnswer = _selectedLetters.join();
    });
  }

  void _removeLetter(int index) {
    setState(() {
      _availableLetters.add(_selectedLetters[index]);
      _selectedLetters.removeAt(index);
      _selectedAnswer = _selectedLetters.join();
    });
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _selectedAnswer = result.recognizedWords;
              _answerController.text = _selectedAnswer;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _checkAnswer() {
    if (_currentQuestionIndex >= _questions.length) return;

    final correctAnswer =
        _questions[_currentQuestionIndex]['answer'].toLowerCase();
    final userAnswer = _selectedAnswer.toLowerCase().trim();

    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showFeedback = true;

      if (_isCorrect) {
        _score += 20;
        _correctAnswers++;
        /* Backend TODO: Save correct answer to backend (API call, database write) */
      } else {
        _score = _score > 10 ? _score - 10 : 0;
        /* Backend TODO: Save incorrect answer to backend (API call, database write) */
      }
    });

    _feedbackAnimationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
          });
          _feedbackAnimationController.reset();

          // Check if this was the last question
          if (_currentQuestionIndex == _questions.length - 1) {
            _submitProgressToFirebase();
          } else if (_isCorrect &&
              _currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
            _selectedAnswer = '';
            _answerController.clear();
            _shuffleLetters();
          }
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showHint() {
    if (_currentQuestionIndex < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_questions[_currentQuestionIndex]['hint']),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _submitProgressToFirebase() async {
    setState(() {
      _isSubmittingProgress = true;
    });

    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || userType != 'student') {
        _showErrorDialog('User not authenticated. Please log in again.');
        return;
      }

      final subjectId = widget.subjectData['id'] ?? 'unknown_subject';
      final topicId = widget.topicData['id'] ?? 'unknown_topic';
      final subjectName = widget.subjectData['name'] ?? 'Unknown Subject';
      final topicName = widget.topicData['name'] ?? 'Unknown Topic';
      final percentage = _totalQuestions > 0
          ? ((_correctAnswers / _totalQuestions) * 100).round()
          : 0;
      final timeSpent = 900 - _timeRemaining;

      final fillupsService = FillupsPostService();
      await fillupsService.submitFillupsResult(
        userId: userId,
        subjectId: subjectId,
        topicId: topicId,
        subjectName: subjectName,
        topicName: topicName,
        score: _score,
        correctAnswers: _correctAnswers,
        totalQuestions: _totalQuestions,
        percentage: percentage,
        timeSpent: timeSpent,
      );

      _showCompletionDialog();
    } catch (e) {
      print('Error submitting progress: $e');
      _showErrorDialog('Failed to save progress. Please try again.');
    } finally {
      setState(() {
        _isSubmittingProgress = false;
      });
    }
  }

  void _showCompletionDialog() {
    final percentage = _totalQuestions > 0
        ? ((_correctAnswers / _totalQuestions) * 100).round()
        : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text('Quiz Completed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Great job! Here are your results:'),
              const SizedBox(height: 15),
              _buildResultRow('Score', '$_score points'),
              _buildResultRow('Correct Answers',
                  '$_correctAnswers out of $_totalQuestions'),
              _buildResultRow('Percentage', '$percentage%'),
              _buildResultRow('Time Spent', _formatTime(900 - _timeRemaining)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      percentage >= 70 ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      percentage >= 70 ? Icons.star : Icons.trending_up,
                      color: percentage >= 70 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        percentage >= 70
                            ? 'Excellent work! Keep it up!'
                            : 'Good effort! Keep practicing to improve.',
                        style: TextStyle(
                          color: percentage >= 70
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildProgressDots(),
                _buildQuestionCard(),
                const Spacer(),
                _buildInputModeSelector(),
                const SizedBox(height: 20),
              ],
            ),
            if (_showFeedback)
              FadeTransition(
                opacity: _feedbackAnimation,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isCorrect ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.close,
                            color: Colors.white,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isCorrect ? 'Correct!' : 'Try Again',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isCorrect) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Correct answer: ${_questions[_currentQuestionIndex]['answer']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isSubmittingProgress)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Saving your progress...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showHint,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.lightbulb_outline),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Back',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Practice Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow),
                Text(' $_score',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_timeRemaining),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(_questions.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= _currentQuestionIndex
                      ? Colors.pink
                      : Colors.grey[300],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_currentQuestionIndex >= _questions.length) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No more questions available',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Text(
            _questions[_currentQuestionIndex]['question'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: _currentInputMode == InputMode.letters
                ? _buildLetterSelection()
                : TextField(
                    controller: _answerController,
                    onChanged: (value) => _selectedAnswer = value,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your answer here',
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Check Answer',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterSelection() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: _selectedLetters.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _removeLetter(entry.key),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry.value),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _availableLetters.map((letter) {
            return GestureDetector(
              onTap: () => _selectLetter(letter),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(letter),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModeButton(
            icon: Icons.keyboard,
            mode: InputMode.text,
            label: 'Type',
          ),
          _buildModeButton(
            icon: Icons.mic,
            mode: InputMode.voice,
            label: 'Speak',
            onPressed: _startListening,
            isListening: _isListening,
          ),
          _buildModeButton(
            icon: Icons.grid_view,
            mode: InputMode.letters,
            label: 'Letters',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required InputMode mode,
    required String label,
    VoidCallback? onPressed,
    bool isListening = false,
  }) {
    final isSelected = _currentInputMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _currentInputMode = mode);
        if (onPressed != null) onPressed();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[200],
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isListening)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _speech.stop();
    _feedbackAnimationController.dispose();
    super.dispose();
  }
}

enum InputMode { text, voice, letters }
