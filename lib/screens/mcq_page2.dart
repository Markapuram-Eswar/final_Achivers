import 'dart:io';
import 'package:flutter/material.dart';
import '../services/TestService.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class McqPage extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> topicData;

  const McqPage({
    super.key,
    required this.subjectData,
    required this.topicData,
  });

  @override
  McqPageState createState() => McqPageState();
}

class McqPageState extends State<McqPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = []; // Initialize with empty list
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  bool _hasSubmitted = false;
  bool _showReview = false;
  int _score = 0;
  bool _isLoading = true;
  final TestService _testService = TestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add speech recognition variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedLanguage = 'en-US';
  late ConfettiController _confettiController;
  String _paragraph = '';
  List<String> matchedKeywords = [];
  List<String> missedKeywords = [];
  double matchPercentage = 0.0;

  // Add fillups variables
  final TextEditingController _answerController = TextEditingController();
  List<String> _selectedLetters = [];
  List<String> _availableLetters = [];
  InputMode _currentInputMode = InputMode.text;

  // Add missing variable
  String _selectedAnswer = '';

  List<dynamic> _userAnswers = [];
  List<bool?> _questionResults = [];
  bool _isSubmitting = false;
  bool _vocalReadyToSubmit = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _initializeSpeech();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoading = true);

      // Fetch questions from Firestore using testId
      final testId = widget.topicData['testId'];
      if (testId == null) {
        throw Exception('Test ID not found');
      }

      print('Loading questions for test ID: $testId'); // Debug log

      // Get the test document
      final testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(testId)
          .get();

      if (!testDoc.exists) {
        throw Exception('Test document not found');
      }

      print('Test document found: ${testDoc.data()}'); // Debug log

      final testData = testDoc.data();
      List<Map<String, dynamic>> questionsList = [];
      if (testData != null && testData['questions'] != null) {
        // Only use MCQ questions
        questionsList = List<Map<String, dynamic>>.from(testData['questions'])
            .where((q) =>
                (q['type'] ?? '').toString().toLowerCase() == 'multiplechoice')
            .map((q) => {
                  'question': q['question'] ?? 'Question not available',
                  'options': List<String>.from(q['options'] ?? []),
                  'correctAnswer': q['correctOptions'] != null &&
                          (q['correctOptions'] as List).isNotEmpty
                      ? (q['correctOptions'] as List).first
                      : 0,
                  'explanation':
                      'This is a ${q['type'] ?? 'multiple choice'} question from section ${q['section'] ?? 'A'}',
                  'type': q['type'] ?? 'multipleChoice',
                  'section': q['section'] ?? 'A',
                })
            .toList();
      }
      if (questionsList.isEmpty &&
          testData != null &&
          testData['questions'] != null) {
        // fallback to previous logic if no MCQ found
        questionsList =
            List<Map<String, dynamic>>.from(testData['questions']).map((q) {
          return {
            'question': q['question'] ?? 'Question not available',
            'options': List<String>.from(q['options'] ?? []),
            'correctAnswer': q['correctOptions'] != null &&
                    (q['correctOptions'] as List).isNotEmpty
                ? (q['correctOptions'] as List).first
                : 0,
            'explanation':
                'This is a ${q['type'] ?? 'multiple choice'} question from section ${q['section'] ?? 'A'}',
            'type': q['type'] ?? 'multipleChoice',
            'section': q['section'] ?? 'A',
          };
        }).toList();
      }
      if (questionsList.isEmpty) {
        throw Exception('No valid questions found in test document');
      }

      if (mounted) {
        setState(() {
          _questions = questionsList;
          _selectedAnswers = List.filled(_questions.length, null);
          _userAnswers = List.filled(_questions.length, null);
          _questionResults = List.filled(_questions.length, null);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading questions: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
          _questions = [];
          _selectedAnswers = [];
          _userAnswers = [];
          _questionResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _allQuestionsAnswered {
    return _questions.isNotEmpty &&
        !_selectedAnswers.any((answer) => answer == null);
  }

  Future<void> _submitQuiz() async {
    if (!_allQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please answer all questions before submitting')),
      );
      return;
    }

    try {
      setState(() => _hasSubmitted = true);
      _showReview = false;
      _score = 0;

      // Calculate score
      for (int i = 0; i < _questions.length; i++) {
        if (_selectedAnswers[i] == _questions[i]['correctAnswer']) {
          _score++;
        }
      }

      // Get student ID from AuthService
      final studentId = await AuthService.getUserId();
      if (studentId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate percentage score
      final percentageScore = (_score / _questions.length) * 100;

      // Update test status
      await _testService.updateTestStatus(
        testId: widget.topicData['testId'],
        studentId: studentId,
        status: 'completed',
        score: _score,
        totalQuestions: _questions.length,
        percentageScore: percentageScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Test submitted successfully! Score: $_score/${_questions.length} (${percentageScore.toStringAsFixed(1)}%)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting test: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkAnswers() {
    setState(() {
      _showReview = true;
    });
  }

  Future<void> _downloadReport() async {
    // Show loading indicator
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Generating report...')),
    );

    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  '${widget.topicData['title']} Quiz Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(widget.subjectData['color'].value),
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // Score Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Quiz Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Score: $_score/${_questions.length} (${(_score / _questions.length * 100).toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(
                          fontSize: 14, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Questions and Answers
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final isCorrect =
                    _selectedAnswers[index] == question['correctAnswer'];
                final userAnswer = _selectedAnswers[index];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: isCorrect ? PdfColors.green : PdfColors.red,
                      width: 1,
                    ),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Question
                      pw.Text(
                        '${index + 1}. ${question['question']}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      // Options
                      ...question['options'].asMap().entries.map((option) {
                        final optionIndex = option.key;
                        final optionText = option.value;
                        final isSelected = userAnswer == optionIndex;
                        final isCorrectOption =
                            question['correctAnswer'] == optionIndex;

                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 16,
                                height: 16,
                                margin:
                                    const pw.EdgeInsets.only(right: 8, top: 2),
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(
                                    color: isCorrectOption
                                        ? PdfColors.green
                                        : isSelected
                                            ? PdfColors.red
                                            : PdfColors.grey,
                                    width: 1.5,
                                  ),
                                ),
                                child: isCorrectOption
                                    ? pw.Center(
                                        child: pw.Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const pw.BoxDecoration(
                                            color: PdfColors.green,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : isSelected
                                        ? pw.Center(
                                            child: pw.Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  const pw.BoxDecoration(
                                                color: PdfColors.red,
                                                shape: pw.BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  optionText,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: isCorrectOption
                                        ? PdfColors.green
                                        : isSelected
                                            ? PdfColors.red
                                            : PdfColors.black,
                                    fontWeight: isCorrectOption || isSelected
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // Explanation
                      if (!isCorrect) ...[
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'Explanation: ${question['explanation']}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey800,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 8),

                      // Status
                      pw.Text(
                        isCorrect ? 'Correct!' : 'Incorrect',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: isCorrect ? PdfColors.green : PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Footer
              pw.Footer(
                title: pw.Text(
                  'Generated by Achievers Learning App',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ];
          },
        ),
      );

      // Save the PDF to a temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/quiz_report.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );

      // Open the file with the device's default PDF viewer
      await OpenFilex.open(file.path);

      // Option to share the file
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'My quiz results from ${widget.topicData['title']} - Score: $_score/${_questions.length}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _initializeSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _speech.initialize();
    }
  }

  void _startListening() async {
    if (!_isListening) {
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
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _matchKeywords(
          _paragraph, _questions[_currentQuestionIndex]['keywords'] ?? []);
    }
  }

  void _matchKeywords(String input, List<String> keywords) {
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

  void _shuffleLetters() {
    if (_currentQuestionIndex < _questions.length) {
      _availableLetters =
          List.from(_questions[_currentQuestionIndex]['jumbledLetters'] ?? []);
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

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _vocalReadyToSubmit = _paragraph.isNotEmpty;
    });
    _matchKeywords(
        _paragraph, _questions[_currentQuestionIndex]['keywords'] ?? []);
  }

  bool _canProceed() {
    final question = _questions[_currentQuestionIndex];
    final type = (question['type'] ?? '').toString().toLowerCase();
    if (type == 'multiplechoice') {
      return _selectedAnswers[_currentQuestionIndex] != null;
    } else if (type == 'fillblanks') {
      return (_userAnswers[_currentQuestionIndex] != null &&
          _userAnswers[_currentQuestionIndex].toString().trim().isNotEmpty);
    } else if (type == 'vocal') {
      return _paragraph.trim().isNotEmpty;
    }
    return false;
  }

  Future<void> _finishQuestion(String type) async {
    setState(() => _isSubmitting = true);
    final idx = _currentQuestionIndex;
    bool isCorrect = false;
    final question = _questions[idx];
    final userAnswer = _userAnswers[idx];
    if (type == 'multiplechoice') {
      isCorrect = userAnswer == question['correctAnswer'];
    } else if (type == 'fillblanks') {
      final correct =
          (question['answer'] ?? '').toString().trim().toLowerCase();
      final user = (userAnswer ?? '').toString().trim().toLowerCase();
      isCorrect = correct == user;
    } else if (type == 'vocal') {
      final spoken = (_paragraph ?? '').toLowerCase();
      final expected = (question['question'] ?? '').toString().toLowerCase();
      final expectedWords =
          expected.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final spokenWords =
          spoken.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      int matched = 0;
      for (final word in expectedWords) {
        if (spokenWords.contains(word)) matched++;
      }
      isCorrect =
          expectedWords.isNotEmpty && (matched / expectedWords.length) >= 0.7;
    }
    _questionResults[idx] = isCorrect;
    await _storeAnswer(idx, type, userAnswer, isCorrect);
    setState(() {
      _isSubmitting = false;
      if (type == 'vocal') {
        _paragraph = '';
        _vocalReadyToSubmit = false;
      }
      if (type == 'fillblanks') _answerController.clear();
    });
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      await _markTestCompleted();
      _showSummary();
    }
  }

  Future<void> _markTestCompleted() async {
    try {
      final userId = await AuthService.getUserId();
      final testId = widget.topicData['testId'];
      if (userId != null && testId != null) {
        // Update the main test document's status for this user
        await FirebaseFirestore.instance.collection('tests').doc(testId).set({
          'status': 'completed',
        }, SetOptions(merge: true));
        // Optionally, also update test_status as before
        await FirebaseFirestore.instance
            .collection('test_status')
            .doc('${testId}_$userId')
            .set({
          'userId': userId,
          'testId': testId,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _storeAnswer(
      int idx, String type, dynamic userAnswer, bool isCorrect) async {
    final userId = await AuthService.getUserId();
    if (userId == null) return;
    final testId = widget.topicData['testId'];
    final answerData = {
      'userId': userId,
      'testId': testId,
      'questionIndex': idx,
      'type': type,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance.collection('test_answers').add(answerData);
  }

  void _showSummary() async {
    final total = _questionResults.length;
    final correct = _questionResults.where((r) => r == true).length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Completed!'),
        content: Text('You scored $correct out of $total.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Pop page and return true
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.topicData['title']} MCQs',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: widget.subjectData['color'],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.topicData['title']} MCQs',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: widget.subjectData['color'],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'No questions available for this test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Define type for the current question
    final String type = (_questions[_currentQuestionIndex]['type'] ?? '')
        .toString()
        .toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.topicData['title']} MCQs',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.subjectData['color'],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            valueColor:
                AlwaysStoppedAnimation<Color>(widget.subjectData['color']),
            minHeight: 8,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_hasSubmitted)
                  Text(
                    'Score: $_score/${_questions.length}',
                    style: TextStyle(
                      color: widget.subjectData['color'],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Question content or review
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:
                  _showReview ? _buildReviewScreen() : _buildCurrentQuestion(),
            ),
          ),

          // Unified Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed:
                      _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: (type == 'vocal' ? _vocalReadyToSubmit && !_isSubmitting : _canProceed() && !_isSubmitting)
                      ? () => _finishQuestion(type)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectData['color'],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.subjectData['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.subjectData['color']),
          ),
          child: Column(
            children: [
              Text(
                'Quiz Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.subjectData['color'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $_score/${_questions.length} (${(_score / _questions.length * 100).toStringAsFixed(0)}%)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...List.generate(_questions.length, (index) {
          final question = _questions[index];
          final isCorrect =
              _selectedAnswers[index] == question['correctAnswer'];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Question ${index + 1}${isCorrect ? ' (Correct)' : ' (Incorrect)'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuestionReview(question, index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionReview(
      Map<String, dynamic> question, int questionIndex) {
    final List<String> options = question['options'];
    final int correctAnswer = question['correctAnswer'];
    final int? selectedAnswer = _selectedAnswers[questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = index == correctAnswer;
          final isSelected = selectedAnswer == index;

          Color bgColor = Colors.grey.shade100;
          Color borderColor = Colors.grey.shade300;
          IconData? icon;
          Color? iconColor;

          if (isCorrect) {
            bgColor = Colors.green.shade50;
            borderColor = Colors.green;
            icon = Icons.check_circle;
            iconColor = Colors.green;
          } else if (isSelected) {
            bgColor = Colors.red.shade50;
            borderColor = Colors.red;
            icon = Icons.cancel;
            iconColor = Colors.red;
          }

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected || isCorrect ? Colors.black87 : null,
                      fontWeight:
                          isSelected || isCorrect ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        if (question['explanation'] != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(question['explanation']),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentQuestion() {
    final question = _questions[_currentQuestionIndex];
    final type = (question['type'] ?? '').toString().toLowerCase();
    final userAnswer = _userAnswers[_currentQuestionIndex];
    final result = _questionResults[_currentQuestionIndex];

    Widget content;
    switch (type) {
      case 'multiplechoice':
        final List<String> options = question['options'];
        final int correctAnswer = question['correctAnswer'];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _questionHeader('MCQ', Icons.check_circle_outline),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(options.length, (index) {
              final isSelected =
                  _selectedAnswers[_currentQuestionIndex] == index;
              return GestureDetector(
                onTap: _hasSubmitted
                    ? null
                    : () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = index;
                          _userAnswers[_currentQuestionIndex] = index;
                        });
                      },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.subjectData['color'].withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? widget.subjectData['color']
                          : Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? widget.subjectData['color']
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? widget.subjectData['color']
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[index],
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  result ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    color: result ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
        break;
      case 'fillblanks':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _questionHeader('Fill in the Blanks', Icons.edit),
            const SizedBox(height: 16),
            Text(
              question['question'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _answerController,
              onChanged: (value) {
                setState(() {
                  _selectedAnswer = value;
                  _userAnswers[_currentQuestionIndex] = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your answer',
              ),
            ),
            if (question['hint'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Hint: ${question['hint']}',
                    style: const TextStyle(color: Colors.orange)),
              ),
            const SizedBox(height: 20),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  result ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    color: result ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
        break;
      case 'vocal':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _questionHeader('Vocal', Icons.mic),
            const SizedBox(height: 16),
            Text(
              question['question'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _paragraph.isEmpty
                        ? 'Read the above text aloud...'
                        : _paragraph,
                    style: TextStyle(
                        fontSize: 16,
                        color:
                            _paragraph.isEmpty ? Colors.grey : Colors.black87),
                  ),
                  if (_isListening)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildLottieOrFallback(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isListening ? _stopListening : _startListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isListening ? Icons.stop : Icons.mic),
                    const SizedBox(width: 8),
                    Text(_isListening ? 'Stop Recording' : 'Start Speaking'),
                  ],
                ),
              ),
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  result ? 'Correct!' : 'Try Again',
                  style: TextStyle(
                    color: result ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
        break;
      default:
        content = const Text('Unsupported question type');
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: content,
      ),
    );
  }

  Widget _buildLottieOrFallback() {
    return FutureBuilder(
      future: precacheImage(
          const NetworkImage(
              'https://assets2.lottiefiles.com/packages/lf20_oCue1F.json'),
          context,
          onError: (e, s) {}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.error == null) {
          return Lottie.network(
            'https://assets2.lottiefiles.com/packages/lf20_oCue1F.json',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.mic, color: Colors.blue, size: 40),
          );
        } else {
          return const Icon(Icons.mic, color: Colors.blue, size: 40);
        }
      },
    );
  }

  Widget _questionHeader(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.subjectData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: widget.subjectData['color']),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: widget.subjectData['color'],
              fontWeight: FontWeight.bold,
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
    _confettiController.dispose();
    _answerController.dispose();
    _speech.stop();
    super.dispose();
  }
}

enum InputMode { text, voice, letters }
