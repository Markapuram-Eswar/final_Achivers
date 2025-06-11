import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_speech/google_speech.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(home: SimpleReadingTracker()));

class SimpleReadingTracker extends StatefulWidget {
  const SimpleReadingTracker({super.key});

  @override
  SimpleReadingTrackerState createState() => SimpleReadingTrackerState();
}

class SimpleReadingTrackerState extends State<SimpleReadingTracker> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isListening = false;
  bool _isProcessing = false;
  int _currentWordIndex = 0;
  String? _audioPath;
  late ServiceAccount _serviceAccount;

  final String paragraph =
      "Flutter is an open-source UI toolkit by Google, Could you please clarify where you want to add more paragraphs? If you're referring to adding more instructional or descriptive paragraphs in your app's UI (e.g., Flutter & Dart), or if you want to add more sample text—like 80% of developers use Flutter—for speech-to-text reading!";
  List<String> _textWords = [];
  List<String> _comparisonWords = [];
  final Set<int> _readIndices = {};
  final Set<int> _skippedIndices = {};

  // Google Cloud Speech-to-Text configuration
  final config = RecognitionConfig(
    encoding: AudioEncoding.LINEAR16,
    sampleRateHertz: 16000,
    languageCode: 'en-US',
    maxAlternatives: 1,
  );

  @override
  void initState() {
    super.initState();
    _initializeText();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadServiceAccount();
  }

  Future<void> _loadServiceAccount() async {
    try {
      final serviceAccountJson = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/service_account.json');
      _serviceAccount = ServiceAccount.fromString(serviceAccountJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load service account')),
        );
      }
      debugPrint('Error loading service account: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
    }
  }

  String _cleanTextForComparison(String text) {
    return text
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll("'", '')
        .replaceAll(',', '')
        .replaceAll('?', '')
        .replaceAll('!', '')
        .replaceAll(';', '')
        .replaceAll(':', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('"', '')
        .replaceAll('—', ' ')
        .replaceAll('–', ' ')
        .replaceAll('…', '')
        .replaceAll('%', '')
        .replaceAll('&', ' and ')
        .replaceAll('/', ' ')
        .replaceAll('*', '')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _cleanTextForDisplay(String text) {
    final words = text.split(' ').where((word) => word.isNotEmpty).toList();
    return words;
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

  void _initializeText() {
    _textWords = _cleanTextForDisplay(paragraph);
    _comparisonWords = _textWords.map(_cleanTextForComparison).toList();
    _readIndices.clear();
    _skippedIndices.clear();
    _currentWordIndex = 0;
  }

  Future<void> _startListening() async {
    if (await Permission.microphone.status != PermissionStatus.granted) {
      await _checkPermissions();
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      _audioPath = '${directory.path}/reading_audio.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _audioPath!,
      );
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    try {
      await _recorder.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = true;
        });
      }

      if (_audioPath != null && await File(_audioPath!).exists()) {
        final audioFile = File(_audioPath!);
        final audioBytes = await audioFile.readAsBytes();

        final speechToText = SpeechToText.viaServiceAccount(_serviceAccount);
        final response = await speechToText.recognize(config, audioBytes);

        if (mounted) {
          final rawSpokenText = response.results.isNotEmpty
              ? response.results.first.alternatives.first.transcript
              : '';
          final spokenText = _cleanTextForComparison(rawSpokenText);
          debugPrint('Raw spoken: "$rawSpokenText"');
          debugPrint('Cleaned spoken: "$spokenText"');

          if (_currentWordIndex < _comparisonWords.length) {
            final expected = _comparisonWords[_currentWordIndex];
            debugPrint('Expected (cleaned): "$expected"');

            if (spokenText.contains(expected)) {
              setState(() {
                _readIndices.add(_currentWordIndex);
                _currentWordIndex++;
              });
            }
          }

          setState(() => _isProcessing = false);
        }

        // Clean up audio file
        await audioFile.delete();
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Audio file not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transcription error: $e')));
      }
      debugPrint('Error during transcription: $e');
      // Clean up audio file on error
      if (_audioPath != null && await File(_audioPath!).exists()) {
        await File(_audioPath!).delete();
      }
    }
  }

  void _skipCurrentWord() {
    if (_currentWordIndex < _textWords.length) {
      setState(() {
        _skippedIndices.add(_currentWordIndex);
        _currentWordIndex++;
      });
    }
  }

  void _reset() {
    if (_isListening) {
      _recorder.stop();
    }
    setState(() {
      _isListening = false;
      _isProcessing = false;
      _initializeText();
    });
    // Clean up any existing audio file
    if (_audioPath != null && File(_audioPath!).existsSync()) {
      File(_audioPath!).deleteSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reading Tracker',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black54,
      ),
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing
            ? null
            : _isListening
            ? _stopListening
            : _startListening,
        backgroundColor: _isProcessing
            ? Colors.grey
            : _isListening
            ? Colors.red[600]
            : Colors.green[600],
        tooltip: _isListening ? 'Stop Listening' : 'Start Listening',
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: LinearProgressIndicator(
              value: _textWords.isEmpty
                  ? 0
                  : (_readIndices.length + _skippedIndices.length) /
                        _textWords.length,
              backgroundColor: Colors.grey[300],
              color: Colors.brown[600],
              minHeight: 6,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 10,
                    children: _textWords.asMap().entries.map((entry) {
                      final index = entry.key;
                      final word = entry.value;
                      final isCurrent = index == _currentWordIndex;
                      final color = _skippedIndices.contains(index)
                          ? Colors.red[600]!
                          : _readIndices.contains(index)
                          ? Colors.green[600]!
                          : isCurrent
                          ? Colors.blue[600]!
                          : Colors.black87;

                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isCurrent ? 22 : 18,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontFamily: 'Georgia',
                          color: color,
                          height: 1.6,
                        ),
                        child: Text('${_capitalizeWord(word)} '),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _skipCurrentWord,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip Word'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.stop();
    _recorder.dispose();
    if (_audioPath != null && File(_audioPath!).existsSync()) {
      File(_audioPath!).deleteSync();
    }
    super.dispose();
  }
}