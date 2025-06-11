import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:achiver_app/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

// Import Firebase Storage
import 'package:achiver_app/services/doubt_service.dart';

class DoubtsPage extends StatefulWidget {
  const DoubtsPage({super.key});

  @override
  State<DoubtsPage> createState() => _DoubtsPageState();
}

String? _currentRollNumber;
String? _currentStudentName;
bool _isAuthenticated = false;

class _DoubtsPageState extends State<DoubtsPage> {
  // Initialize services properly
  late DoubtService _doubtService;
  late GeminiService _geminiService;

  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final ScrollController _scrollController = ScrollController();

  String? _currentUserId;
  String? _selectedSubject;
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];

  // List of predefined subjects
  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Social Studies',
    'Computer Science',
    'Other'
  ];

  // Stream subscription for messages of the selected subject
  Stream<QuerySnapshot>? _messagesStream;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {}); // rebuild to update the send button state
    });
    _doubtService = DoubtService();
    _geminiService = GeminiService();
    _checkRollNumberAndAuthenticate();
  }

  bool _rollNumberValid = false;
  bool _rollNumberChecked = false;

  Future<void> _checkRollNumberAndAuthenticate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedRollNumber = prefs.getString('student_roll_number');
    if (savedRollNumber != null) {
      // Check Firestore for a match
      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('rollNumber', isEqualTo: savedRollNumber)
          .limit(1)
          .get();
      if (studentQuery.docs.isNotEmpty) {
        var studentData = studentQuery.docs.first.data() as Map<String, dynamic>;
        String studentName = studentData['name'] ?? 'Student';
        setState(() {
          _currentRollNumber = savedRollNumber;
          _currentStudentName = studentName;
          _rollNumberValid = true;
          _rollNumberChecked = true;
        });
      } else {
        setState(() {
          _currentRollNumber = null;
          _currentStudentName = null;
          _rollNumberValid = false;
          _rollNumberChecked = true;
        });
      }
    } else {
      setState(() {
        _currentRollNumber = null;
        _currentStudentName = null;
        _rollNumberValid = false;
        _rollNumberChecked = true;
      });
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_roll_number');
    await prefs.remove('student_name');
    setState(() {
      _currentRollNumber = null;
      _currentStudentName = null;
      _selectedSubject = null;
      _messages.clear();
      _messagesStream = null;
      _rollNumberValid = false;
      _rollNumberChecked = true;
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // A helper to initialize or re-initialize the messages stream
  void _initializeMessagesStream() {
    if (_currentRollNumber != null && _selectedSubject != null) {
      _messagesStream = _doubtService.getSubjectMessages(
        _currentRollNumber!, // Use roll number instead of user ID
        _selectedSubject!,
      );
    } else {
      _messagesStream = null;
      setState(() {
        _messages = [];
      });
    }
  }

  // Handles subject selection and initializes the messages stream
  void _onSubjectSelected(String subject) {
    setState(() {
      _selectedSubject = subject;
      _messages = [];
      _initializeMessagesStream();
    });
  }

  // This method now scrolls to the *bottom* (latest messages)
  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position.maxScrollExtent;
        if (smooth) {
          _scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(position);
        }
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty ||
        _currentRollNumber == null ||
        _selectedSubject == null) {
      return;
    }

    /// Display user's message immediately (optimistic update)
    setState(() {
      _messages.insert(0, {
        "type": "text",
        "content": text,
        "isUser": true,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final String prompt = _selectedSubject != null
          ? 'Regarding $_selectedSubject: $text'
          : text;

      final geminiResponse = await _geminiService.generateResponse(prompt);

      // Save user's message to Firestore using roll number
      await _doubtService.addMessageToSubjectChat(
        userId: _currentRollNumber!, // Changed from _currentUserId
        subjectId: _selectedSubject!,
        message: text,
        isUser: true,
      );

      // Save AI's response to Firestore
      await _doubtService.addMessageToSubjectChat(
        userId: _currentRollNumber!, // Changed from _currentUserId
        subjectId: _selectedSubject!,
        message: geminiResponse,
        isUser: false,
      );

      // Display AI response in UI
      setState(() {
        _messages.insert(0, {
          "type": "text",
          "content": geminiResponse,
          "isUser": false,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      });
      _scrollToBottom();
      _textController.clear();
    } catch (e) {
      // ... keep existing error handling code
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (_currentRollNumber == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first.')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      // ... keep existing image display code ...

      try {
        // Upload image to Firebase Storage
        final imageUrl = await _doubtService.uploadImage(File(image.path));

        final geminiResponse = await _geminiService.analyzeImage(
            image.path, 'Analyze this image related to $_selectedSubject:');

        // Save user's image message to Firestore using roll number
        await _doubtService.addMessageToSubjectChat(
          userId: _currentRollNumber!, // Changed from _currentUserId
          subjectId: _selectedSubject!,
          message: 'Image shared for $_selectedSubject',
          imageUrl: imageUrl,
          isUser: true,
        );

        // Save AI's response to Firestore using roll number
        await _doubtService.addMessageToSubjectChat(
          userId: _currentRollNumber!, // Changed from _currentUserId
          subjectId: _selectedSubject!,
          message: geminiResponse,
          isUser: false,
        );

        // ... keep existing response display code ...
      } catch (e) {
        // ... keep existing error handling code
      }
    } catch (e) {
      // ... keep existing error handling code
    } finally {
      setState(() => _isLoading = false);
    }
  }

// This method should already exist in your code - here it is for reference
  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'] == true;
    final messageContent = message['content'];
    final messageType = message['type'];
    final imageUrl = message['imageUrl'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: Radius.circular(isUser ? 5 : 20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor:
                      isUser ? Colors.blue.shade100 : Colors.purple.shade100,
                  radius: 16,
                  child: Icon(
                    isUser ? Icons.person : Icons.school,
                    color:
                        isUser ? Colors.blue.shade700 : Colors.purple.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isUser ? 'You' : 'Study Buddy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isUser ? Colors.blue.shade700 : Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (messageType == 'text')
              SelectableText(
                messageContent,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  height: 1.5,
                ),
              )
            else if (messageType == 'image' && imageUrl != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Image.file(File(messageContent)),
                  ),
                ),
              ),
            if (messageType == 'image' &&
                isUser &&
                messageContent is String &&
                !messageContent.startsWith('http'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Your image question',
                  style: TextStyle(
                      color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),
            if (messageType == 'image' && !isUser && messageContent is String)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SelectableText(
                  messageContent,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wait for roll number check
    if (!_rollNumberChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // If roll number is not valid, show a message
    if (!_rollNumberValid) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Roll number not found or not set.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please contact your administrator.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Study Buddy${_currentStudentName != null ? ' - $_currentStudentName' : ''}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.school, color: Colors.purple.shade400),
                      const SizedBox(width: 8),
                      const Text('Welcome to Study Buddy!'),
                    ],
                  ),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I\'m your personal AI study assistant! Here\'s how I can help:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('• Ask any academic questions'),
                      Text('• Upload images of problems or notes'),
                      Text('• Get step-by-step explanations'),
                      Text('• Practice with sample questions'),
                      Text('• Understand complex concepts'),
                      SizedBox(height: 12),
                      Text(
                        'Just type your question or upload an image to get started!',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Got it!'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subject selection dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Please select a subject...'),
                  ),
                  ..._subjects.map((subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      )),
                ],
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    _onSubjectSelected(value);
                  } else {
                    setState(() {
                      _selectedSubject = null;
                      _messages = [];
                      _initializeMessagesStream();
                    });
                  }
                },
                isExpanded: true,
                icon:
                    Icon(Icons.arrow_drop_down, color: Colors.purple.shade700),
              ),
            ),
            Expanded(
              child: _selectedSubject == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subject,
                            size: 72,
                            color: Colors.purple.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a Subject to Start Chatting!',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your conversations will be saved per subject.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 72,
                                  color: Colors.purple.shade200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hello! I\'m your Study Buddy for $_selectedSubject!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ask me anything about $_selectedSubject',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.shade100
                                            .withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSuggestion(
                                        'What are Newton\'s laws of motion?',
                                        Icons.speed,
                                      ),
                                      const Divider(),
                                      _buildSuggestion(
                                        'How do I solve quadratic equations?',
                                        Icons.functions,
                                      ),
                                      const Divider(),
                                      _buildSuggestion(
                                        'Explain photosynthesis process',
                                        Icons.nature,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Reconstruct _messages list from snapshot
                        _messages = snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'id': doc.id,
                            'type': data['imageUrl'] != null ? 'image' : 'text',
                            'content': data['imageUrl'] ?? data['message'],
                            'imageUrl': data['imageUrl'],
                            'isUser': data['isUser'],
                            'timestamp': (data['timestamp'] as Timestamp?)
                                    ?.toDate()
                                    .millisecondsSinceEpoch ??
                                0,
                          };
                        }).toList();

                        // Sort messages by timestamp
                        _messages.sort((a, b) => (a['timestamp'] as int)
                            .compareTo(b['timestamp'] as int));

                        // Scroll to bottom after new messages arrive

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount:
                              _isLoading ? _messages.length : _messages.length,
                          itemBuilder: (_, index) {
                            if (_isLoading && index == _messages.length) {
                              // Show shimmer or loading widget at the end
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Align(
                                  alignment:
                                      Alignment.centerLeft, // mimic AI response
                                  child: Shimmer.fromColors(
                                    baseColor:
                                        const Color.fromARGB(255, 104, 87, 87),
                                    highlightColor:
                                        const Color.fromARGB(255, 121, 86, 86),
                                    child: Container(
                                      height: 60,
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 68, 42, 42),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return _buildMessage(_messages[index]);
                          },
                        );
                      },
                    ),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Thinking...',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.image_outlined),
                      color: Colors.purple.shade700,
                      onPressed: _isLoading || _selectedSubject == null
                          ? null
                          : _pickImage,
                      tooltip: 'Upload an image',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              enabled: !_isLoading && _selectedSubject != null,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: _selectedSubject == null
                                    ? "Please select a subject above to chat"
                                    : (_isLoading
                                        ? "Please wait..."
                                        : "Ask your question here..."),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (value) {
                                if (!_isLoading &&
                                    _selectedSubject != null &&
                                    value.trim().isNotEmpty) {
                                  _messages.add({
                                    'type': 'thinking',
                                    'content': 'Thinking...',
                                    'isUser': false,
                                  });
                                  _sendText();
                                }
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: Colors.purple.shade700,
                              ),
                              onPressed: (!_isLoading &&
                                      _selectedSubject != null &&
                                      _textController.text.trim().isNotEmpty)
                                  ? _sendText
                                  : null,
                              tooltip: 'Send message',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectedSubject == null || _isLoading
            ? null
            : () {
                _textController.text = text;
                _sendText();
              },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.purple.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
