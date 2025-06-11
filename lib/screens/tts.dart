import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/textbook_service.dart';

class SimpleReadingTracker extends StatelessWidget {
  final String classNumber;
  final String subject;
  final String topic;

  const SimpleReadingTracker({
    Key? key,
    required this.classNumber,
    required this.subject,
    required this.topic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'NotoSansTamil',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: WordByWordScorer(
        classNumber: classNumber,
        subject: subject,
        topic: topic,
      ),
    );
  }
}

class ParagraphBlock {
  final String heading;
  final String paragraph;
  final String imagePath;

  ParagraphBlock({
    required this.heading,
    required this.paragraph,
    required this.imagePath,
  });

  factory ParagraphBlock.fromMap(Map<String, dynamic> map) {
    return ParagraphBlock(
      heading: map['heading'] ?? '',
      paragraph: map['paragraph'] ?? '',
      imagePath: map['image'] ?? '',
    );
  }
}

class WordByWordScorer extends StatefulWidget {
  final String classNumber;
  final String subject;
  final String topic;

  const WordByWordScorer({
    Key? key,
    required this.classNumber,
    required this.subject,
    required this.topic,
  }) : super(key: key);

  @override
  State<WordByWordScorer> createState() => _WordByWordScorerState();
}

class _WordByWordScorerState extends State<WordByWordScorer> {
  final SpeechToText _speech = SpeechToText();
  final TextbookService _textbookService = TextbookService();
  bool _isSpeechInitialized = false;
  int? _activeBlockIndex;
  String _recognizedText = '';
  String? _errorMessage;
  bool _isListening = false;
  List<ParagraphBlock> paragraphBlocks = [];
  bool _isLoading = true;
  String _currentDescription = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _checkPermissions();
    _loadParagraphs();
  }

  Future<void> _loadParagraphs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final lessons = await _textbookService.getTextbookContent(
        classNumber: widget.classNumber,
        subject: widget.subject,
        topic: widget.topic,
      );

      if (mounted) {
        setState(() {
          paragraphBlocks =
              lessons.map((lesson) => ParagraphBlock.fromMap(lesson)).toList();
          if (paragraphBlocks.isNotEmpty) {
            _currentDescription = paragraphBlocks[0].paragraph;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isListening) _speech.stop();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('மைக்ரோபோன் அனுமதி தேவை.')),
        );
      }
    }
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onError: (val) {
        if (mounted) {
          setState(() {
            _errorMessage = 'பேச்சு அடையாள பிழை: ${val.errorMsg}';
            _isListening = false;
            _activeBlockIndex = null;
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _isSpeechInitialized = available;
        if (!available) {
          _errorMessage = 'பேச்சு அடையாளத்தை தொடங்க முடியவில்லை.';
        }
      });
    }
  }

  void _startListening(int blockIndex, List<String> comparisonWords,
      Function(int, int, bool, Set<int>) onProgress) async {
    if (!_isSpeechInitialized || _isListening) return;

    setState(() {
      _activeBlockIndex = blockIndex;
      _isListening = true;
      _recognizedText = '';
      _errorMessage = null;
    });

    _speech.listen(
      localeId: 'ta-IN',
      partialResults: true,
      onResult: (val) {
        if (!mounted) return;

        final spoken = _cleanTextForComparison(val.recognizedWords);
        setState(() {
          _recognizedText = spoken;
        });

        // Compare spoken text with description
        final spokenWords =
            spoken.split(' ').where((word) => word.isNotEmpty).toList();
        final descriptionWords = _currentDescription
            .split(' ')
            .where((word) => word.isNotEmpty)
            .toList();

        int correctWords = 0;
        Set<int> correctIndices = {};

        for (int i = 0;
            i < spokenWords.length && i < descriptionWords.length;
            i++) {
          if (spokenWords[i].toLowerCase() ==
              descriptionWords[i].toLowerCase()) {
            correctWords++;
            correctIndices.add(i);
          }
        }

        onProgress(
          spokenWords.length,
          descriptionWords.length,
          spokenWords.length >= descriptionWords.length,
          correctIndices,
        );
      },
    );
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _activeBlockIndex = null;
      });
    }
  }

  String _cleanTextForComparison(String input) {
    return input
        .replaceAll(RegExp(r'[^\u0B80-\u0BFF\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 ${widget.topic} - ${widget.subject}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_currentDescription.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Description:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentDescription,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadParagraphs,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: paragraphBlocks.length,
                  itemBuilder: (context, index) {
                    return ParagraphBlockWidget(
                      blockIndex: index,
                      block: paragraphBlocks[index],
                      isActive: _activeBlockIndex == index,
                      isAnyBlockActive: _activeBlockIndex != null,
                      recognizedText: _recognizedText,
                      errorMessage: _errorMessage,
                      onStartListening: _startListening,
                      onStopListening: _stopListening,
                    );
                  },
                ),
    );
  }
}

class ParagraphBlockWidget extends StatefulWidget {
  final int blockIndex;
  final ParagraphBlock block;
  final bool isActive;
  final bool isAnyBlockActive;
  final String recognizedText;
  final String? errorMessage;
  final Function(int, List<String>, Function(int, int, bool, Set<int>))
      onStartListening;
  final VoidCallback onStopListening;

  const ParagraphBlockWidget({
    Key? key,
    required this.blockIndex,
    required this.block,
    required this.isActive,
    required this.isAnyBlockActive,
    required this.recognizedText,
    required this.errorMessage,
    required this.onStartListening,
    required this.onStopListening,
  }) : super(key: key);

  @override
  State<ParagraphBlockWidget> createState() => _ParagraphBlockWidgetState();
}

class _ParagraphBlockWidgetState extends State<ParagraphBlockWidget> {
  late List<String> _comparisonWords;
  int _currentWordIndex = 0;
  int _correctCount = 0;
  bool _completed = false;
  final Set<int> _skippedIndices = {};

  @override
  void initState() {
    super.initState();
    _comparisonWords = _convertParagraphToKeywords(widget.block.paragraph);
  }

  String _cleanTextForComparison(String input) {
    return input
        .replaceAll(RegExp(r'[^\u0B80-\u0BFF\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  List<String> _convertParagraphToKeywords(String paragraph) {
    return _cleanTextForComparison(paragraph)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  void _startListening() {
    if (widget.isAnyBlockActive && !widget.isActive) return;

    widget.onStartListening(widget.blockIndex, _comparisonWords,
        (currentIndex, correctCount, completed, skippedIndices) {
      if (!mounted) return;
      setState(() {
        _currentWordIndex = currentIndex;
        _correctCount = correctCount;
        _completed = completed;
        _skippedIndices.addAll(skippedIndices);
      });

      final spokenWords = widget.recognizedText
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList();

      if (_currentWordIndex < _comparisonWords.length) {
        final expected =
            _cleanTextForComparison(_comparisonWords[_currentWordIndex]);
        if (spokenWords.contains(expected)) {
          setState(() {
            _correctCount++;
            _currentWordIndex++;
          });
        }
      }

      if (_currentWordIndex >= _comparisonWords.length) {
        _stopListening();
      }
    });
  }

  void _stopListening() {
    widget.onStopListening();
    if (mounted) {
      setState(() {
        _completed = true;
      });
    }
  }

  void _reset() {
    setState(() {
      _completed = false;
      _currentWordIndex = 0;
      _correctCount = 0;
      _skippedIndices.clear();
    });
  }

  void _skipCurrentWord() {
    if (_currentWordIndex < _comparisonWords.length) {
      setState(() {
        _skippedIndices.add(_currentWordIndex);
        _currentWordIndex++;
      });

      if (widget.isActive && !_completed) {
        widget.onStopListening();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && widget.isActive) {
            _startListening();
          }
        });
      }

      if (_currentWordIndex >= _comparisonWords.length) {
        _stopListening();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scorePercent = _comparisonWords.isEmpty
        ? 0
        : (_correctCount / _comparisonWords.length) * 100;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book,
                        color: Colors.deepOrange.shade700, size: 25),
                    const SizedBox(width: 12),
                    Text(
                      widget.block.heading,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange.shade900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Image with frame
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.block.imagePath,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.block.paragraph,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Controls Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (widget.isActive && widget.recognizedText.isNotEmpty)
                      _buildCard('🎧 What you said:', widget.recognizedText,
                          Colors.blue.shade50),
                    if (_completed)
                      _buildCard(
                        '✅ Completed!',
                        'Total Score: $_correctCount / ${_comparisonWords.length} (${(_correctCount / _comparisonWords.length * 100).toStringAsFixed(1)}%)',
                        Colors.green.shade50,
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: 105,
                          child: ElevatedButton.icon(
                            onPressed: widget.isActive
                                ? _stopListening
                                : (!widget.isAnyBlockActive
                                    ? _startListening
                                    : null),
                            icon: Icon(
                              widget.isActive ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: Text(
                              widget.isActive ? 'Stop' : 'Start',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange.shade400,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: widget.isActive && !_completed
                                ? _skipCurrentWord
                                : null,
                            icon: const Icon(
                              Icons.skip_next,
                              size: 16,
                            ),
                            label: const Text(
                              'Skip',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade400,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 105,
                          child: ElevatedButton.icon(
                            onPressed: widget.isActive ? _reset : null,
                            icon: const Icon(
                              Icons.refresh,
                              size: 16,
                            ),
                            label: const Text(
                              'Reset',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String content, Color color) {
    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
