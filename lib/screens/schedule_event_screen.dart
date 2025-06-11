import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show min;
import '../services/AssessmentService.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/fcm/v1.dart' as fcm;
import '../services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    const MaterialApp(
      home: SendMessageScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({super.key});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _manualTokenController = TextEditingController();

  String? _selectedClass;
  String? _selectedSection;
  List<String> _selectedStudents = [];
  String _recipientType = 'Both';
  bool _useManualToken = false;

  final List<String> _classes =
      List.generate(12, (index) => 'Class ${index + 1}');
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  Future<String> _getAccessToken() async {
    try {
      // Use the service account JSON directly
      final Map<String, dynamic> serviceAccountMap = {
        "type": "service_account",
        "project_id": "achievers-vap",
        "private_key_id": "8478db4c0be5121eec4e71af1a5375fb55f48a67",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7iCRii9VV7hE3\nm0KTm/Kc0M3PnAe6w2QlXU4+oRWeiEiCj6GOWr5KCGYUqB5Gv01UrE11HrfRnEr3\nF5t2qgmhBRdW/EqJf81dCD719JN7m0KtdV9QF1cUTKoiYbYGrhyBzHJnciRo2r5N\nR4YzPApJZVAmm2yFmXIwSP8K29YkLC6YmAC8DeHqHe/CHjdvdD7618QwcHae2pNq\nR1YkFGciXnk1vU6TuCDB919PF7EIiLz6hVj1dk0rseQqPvQL9UZXGWdoPPL/Vfqt\n9Brfcw9IfUttydYjcKFcfrJW4NUPnFvAV9RpCL9EXomuIWGmJPdnMfXI4EX2O8Rm\nilta7+1dAgMBAAECggEAM5tEgAYBIFOSU14blSleO39Ok+pZSjEI9ytVI/EKVQUm\nBx/lkpowMYlcJiUZp9hvPHTqH+fjKAC9tH+/nYkveys+gAaPsIUGC6sAQIkcqPBS\nCg/5ub2ijgiG7U08XVw+pg2QEh2cHWrM4dFkAeds4UPLKcStuZo/jUAZR3C13l/9\nlaDKV/AkyGtLuiK+ZuwcuHoo4SvJjwMjIQV18+/nXORXW0DrjMRsXEBl9I8Go9FM\nv+ARWmnXQrD/qhGm+AqLUNTY5QWpbGN5Zk5tapOr4hGNcetF6RwLzIrC6psCYgz4\n6KgjBcitc5H+xjSGTRjC/5WjWimZA+3I/1kvAiOgdQKBgQDgf43/7qDygD8rLfT/\nWP8CPNq7nU6MRnz1WucksBeRhuIeRhbKmnsY4HVJVck/jLb7xFOP+qplgzZ1VWBU\nbcEFagt/Cq2cjIl6UrMYG1TvTGsXkt4R6iPAfcinywU7fqpsnSmgSzQ7YReEpiV5\niFopUW85NAXyLHpn21THJS63fwKBgQDV2KzjBqa9Wvb3t0Hz4ya7XS7LdlJ3AKWy\nGcICOM/yXlqN5ow62OrpwBVPPE4oFeN9bg2K/8ar9lJghbroyArmTVzOJl0C7TNU\ninB3pQB3QcKw8hcwtThPyubSVJXDMrr1fNjmATCMveHoDp9zL7u6nofxhBqZF8zY\nkxIPFpapIwKBgEW/O1W9RKGyuG1o3MoMU0XVtDs/tyybpazwrglW8CuVVWEEc4ZE\nkmP7MFU1Ys3soNj9eNytiwz4xA2WFdSFOMe+142DusZ9XyTy1pNxwmSKQGdViMrW\nDH98VL/Usm52fuo5tboIQ1UDaDQdDl2AwEo/86c5A3Pm36yults8MRRvAoGASaRx\nfUkoGKN/0zTX0I5UI0fmuoiHw5WEej3mku9PpU6a7q0Lc6SJ2W+dpwjEfYd0LRi+\nLzUADO4p1jWXdVyWbFMN96w8caqP97gpHPrEm00ZJ+hm1g5CUzAzpxEb9fm9apbQ\n9vxH5N/rMQgAHyG8C3tWo3Rz2G7ay2ZyXKHRxnMCgYEAzTmfRmaHh8pcIEb0WSXo\n9x2Ejs1fRoupCNGpH+QFItdm2NLz1LAInkVKYKYVC5zWEE/Sj1GqP13WgAPYFGwL\n4c0AsQbvo1D8Wu3BHei/0nkCBHIZ+Bh0yGbwOXYTGQG9IxQs5Tl/VwDryYPlVcHE\nX0MCUEJ0t+/Hs30QypfwDH4=\n-----END PRIVATE KEY-----\n",
        "client_email":
            "notification-by-gnana@achievers-vap.iam.gserviceaccount.com",
        "client_id": "110492445218388429283",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/notification-by-gnana%40achievers-vap.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      };

      var accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountMap);
      var scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      var client = await clientViaServiceAccount(accountCredentials, scopes);
      var accessToken = client.credentials.accessToken.data;
      client.close();

      return accessToken;
    } catch (e) {
      print('Error getting access token: $e');
      throw e;
    }
  }

  // Function to get FCM tokens for selected recipients
  Future<List<String>> _getRecipientTokens() async {
    Set<String> tokens = {};
    print('\n=== DEBUG: Starting token retrieval ===');
    print('Selected Class: $_selectedClass');
    print('Selected Section: $_selectedSection');
    print('Selected Students: $_selectedStudents');
    print('Recipient Type: $_recipientType');

    try {
      // Query students collection
      Query query = FirebaseFirestore.instance.collection('students');

      // Add filters for class and section
      if (_selectedClass != null) {
        query = query.where('class', isEqualTo: _selectedClass);
        print('Filtering by class: $_selectedClass');
      }
      if (_selectedSection != null) {
        query = query.where('section', isEqualTo: _selectedSection);
        print('Filtering by section: $_selectedSection');
      }

      print('\nExecuting Firestore query...');
      QuerySnapshot studentSnapshot = await query.get();
      print('Found ${studentSnapshot.docs.length} students in database');

      if (studentSnapshot.docs.isEmpty) {
        print(
            'WARNING: No students found for class $_selectedClass and section $_selectedSection');
        return [];
      }

      print('\nProcessing student documents...');
      for (QueryDocumentSnapshot studentDoc in studentSnapshot.docs) {
        try {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final rollNumber = studentData['rollNumber']?.toString() ?? '';
          final name = studentData['name']?.toString() ?? '';
          final identifier = rollNumber.isNotEmpty ? rollNumber : name;

          if (_selectedStudents.contains(identifier)) {
            // Add Student FCM Token if needed
            if (_recipientType == 'Only Students' || _recipientType == 'Both') {
              final studentToken = studentData['studentFCMToken']?.toString();
              if (studentToken != null && studentToken.isNotEmpty) {
                // Validate token format
                if (_isValidFCMToken(studentToken)) {
                  tokens.add(studentToken);
                  print('Added student token for $identifier');
                } else {
                  print('Invalid student FCM token format for $identifier');
                }
              }
            }

            // Add Parent FCM Token if needed
            if (_recipientType == 'Only Parents' || _recipientType == 'Both') {
              final parentId = studentData['parentId']?.toString();
              if (parentId != null && parentId.isNotEmpty) {
                try {
                  final parentDoc = await FirebaseFirestore.instance
                      .collection('parents')
                      .doc(parentId)
                      .get();

                  if (parentDoc.exists) {
                    final parentData = parentDoc.data() as Map<String, dynamic>;
                    final parentToken =
                        parentData['parentFCMToken']?.toString();
                    if (parentToken != null && parentToken.isNotEmpty) {
                      // Validate token format
                      if (_isValidFCMToken(parentToken)) {
                        tokens.add(parentToken);
                        print('Added parent token for student $identifier');
                      } else {
                        print(
                            'Invalid parent FCM token format for student $identifier');
                      }
                    }
                  }
                } catch (e) {
                  print('Error querying parent document: $e');
                }
              }
            }
          }
        } catch (e) {
          print('Error processing student document: $e');
          continue;
        }
      }

      print('\n=== Final tokens collected: ${tokens.length} ===');
      return tokens.toList();
    } catch (e) {
      print('ERROR in _getRecipientTokens: $e');
      throw e;
    }
  }

  bool _isValidFCMToken(String token) {
    // Basic FCM token validation
    // FCM tokens are typically long strings with specific patterns
    return token.length >= 100 && token.contains(':');
  }

  // Function to send FCM notification
  Future<void> _sendFCMNotification(
      List<String> tokens, String title, String body) async {
    if (tokens.isEmpty) {
      print('No tokens to send notifications to');
      return;
    }

    print('=== Sending FCM notifications ===');
    print('Title: $title');
    print('Body: $body');
    print('Tokens count: ${tokens.length}');

    try {
      String accessToken = await _getAccessToken();
      print('Access token obtained successfully');

      String projectId = "achievers-vap";
      int successCount = 0;
      int failCount = 0;

      // Send to each token individually
      for (int i = 0; i < tokens.length; i++) {
        String token = tokens[i];
        print(
            'Sending to token ${i + 1}/${tokens.length}: ${token.substring(0, min(30, token.length))}...');

        try {
          final message = {
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'message_type': 'school_message',
                'class': _selectedClass ?? '',
                'section': _selectedSection ?? '',
                'recipient_type': _recipientType,
                'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              },
              'android': {
                'priority': 'high',
                'notification': {
                  'title': title,
                  'body': body,
                  'sound': 'default',
                  'channel_id': 'high_importance_channel',
                  'default_sound': true,
                  'default_vibrate_timings': true,
                  'default_light_settings': true,
                  'notification_priority': 'PRIORITY_MAX',
                  'visibility': 'PUBLIC',
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'tag': 'school_message'
                }
              },
              'apns': {
                'headers': {'apns-priority': '10', 'apns-push-type': 'alert'},
                'payload': {
                  'aps': {
                    'alert': {'title': title, 'body': body},
                    'sound': 'default',
                    'badge': 1,
                    'content-available': 1,
                    'mutable-content': 1,
                    'category': 'FLUTTER_NOTIFICATION_CLICK'
                  }
                }
              }
            }
          };

          final response = await http.post(
            Uri.parse(
                'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(message),
          );

          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          if (response.statusCode == 200) {
            successCount++;
            print('✓ Success for token ${i + 1}');
          } else {
            failCount++;
            print('✗ Failed for token ${i + 1}: ${response.body}');

            // Handle specific error cases
            if (response.statusCode == 404) {
              print('Token not found or invalid');
            } else if (response.statusCode == 403) {
              print(
                  'Permission denied. Please check service account permissions.');
            }
          }

          // Small delay between requests to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failCount++;
          print('✗ Exception for token ${i + 1}: $e');
        }
      }

      print('=== FCM Results ===');
      print('Success: $successCount');
      print('Failed: $failCount');
      print('Total: ${tokens.length}');

      if (successCount == 0) {
        throw Exception('All notifications failed to send');
      }
    } catch (e) {
      print('ERROR in _sendFCMNotification: $e');
      throw e;
    }
  }

  Future<void> _testFCM() async {
    try {
      print('Testing FCM setup...');
      String accessToken = await _getAccessToken();
      print('✓ Access token obtained');

      // Test with a hardcoded token (replace with a real token from your device)
      List<String> testTokens = ['YOUR_DEVICE_FCM_TOKEN_HERE'];
      await _sendFCMNotification(testTokens, 'Test Title', 'Test Message');
      print('✓ Test notification sent');
    } catch (e) {
      print('✗ Test failed: $e');
    }
  }

  List<String> _availableStudents = [];
  bool _isLoadingStudents = false;

  // Updated function to load students using AssessmentService
  Future<void> _loadStudents() async {
    if (_selectedClass != null && _selectedSection != null) {
      setState(() {
        _isLoadingStudents = true;
        _availableStudents.clear();
        _selectedStudents.clear();
      });

      try {
        final assessmentService = AssessmentService();
        final students = await assessmentService.getStudentsByClassAndSection(
          _selectedClass!,
          _selectedSection!,
        );

        List<String> studentIdentifiers = students.map((student) {
          // Use rollNumber (matching your database structure) instead of rollNo
          return student['rollNumber']?.toString().isNotEmpty == true
              ? student['rollNumber'].toString()
              : student['name'].toString();
        }).toList();

        setState(() {
          _availableStudents = studentIdentifiers;
          _isLoadingStudents = false;
        });

        print(
            'Loaded ${studentIdentifiers.length} students for $_selectedClass - $_selectedSection');
      } catch (e) {
        print('Error loading students: $e');
        setState(() {
          _isLoadingStudents = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading students: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _availableStudents.clear();
        _selectedStudents.clear();
      });
    }
  }

// Function to send topic-based notification (alternative approach)
  Future<void> _sendTopicNotification(String title, String body) async {
    try {
      String accessToken = await _getAccessToken();

      // Get project ID from your service account JSON

      String projectId = 'achievers-vap';

      final String fcmUrl =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // Create topic based on class, section, and recipient type
      String topic = '${_selectedClass}${_selectedSection}$_recipientType'
          .replaceAll(' ', '_')
          .toLowerCase();

      final Map<String, dynamic> message = {
        'message': {
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'message_type': 'school_message',
            'class': _selectedClass ?? '',
            'section': _selectedSection ?? '',
            'recipient_type': _recipientType,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
          'android': {
            'priority': 'high',
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
          },
        }
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('Topic notification sent successfully to: $topic');
      } else {
        print('Failed to send topic notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending topic notification: $e');
      throw e;
    }
  }

  void _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one student'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('=== Starting message send process ===');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Sending message...'),
            ],
          ),
        ),
      );

      try {
        print('Step 1: Storing message in Firestore...');
        // Store message in Firestore
        DocumentReference messageRef =
            await FirebaseFirestore.instance.collection('messages').add({
          'title': _titleController.text.trim(),
          'body': _messageController.text.trim(),
          'class': _selectedClass,
          'section': _selectedSection,
          'students': _selectedStudents,
          'recipientType': _recipientType,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'status': 'sent',
          'notificationSent': false,
          'recipientCount': 0,
        });
        print('Message stored with ID: ${messageRef.id}');

        print('Step 2: Getting recipient tokens...');
        // Get recipient tokens
        List<String> recipientTokens = await _getRecipientTokens();
        print('Retrieved ${recipientTokens.length} tokens');

        if (recipientTokens.isEmpty) {
          throw Exception('No valid FCM tokens found for selected recipients');
        }

        print('Step 3: Sending FCM notifications...');
        // Send FCM notifications
        await _sendFCMNotification(
          recipientTokens,
          _titleController.text.trim(),
          _messageController.text.trim(),
        );

        print('Step 4: Updating message status...');
        // Update message status
        await messageRef.update({
          'notificationSent': true,
          'recipientCount': recipientTokens.length,
        });

        // Hide loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Message sent to $_recipientType successfully! (${recipientTokens.length} recipients)'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedStudents.clear();
        });
      } catch (e) {
        print('ERROR in _sendMessage: $e');
        // Hide loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool allSelected = _availableStudents.isNotEmpty &&
        _selectedStudents.length == _availableStudents.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add manual token input section at the top
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _useManualToken,
                            onChanged: (value) {
                              setState(() {
                                _useManualToken = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Use Manual FCM Token',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_useManualToken) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _manualTokenController,
                          decoration: const InputDecoration(
                            labelText: 'Enter FCM Token',
                            border: OutlineInputBorder(),
                            hintText: 'Paste FCM token here for testing',
                          ),
                          validator: (value) {
                            if (_useManualToken &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter FCM token';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Note: This will override the automatic token collection',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Class Dropdown
              const Text(
                'Class',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                items: _classes.map((cls) {
                  return DropdownMenuItem(value: cls, child: Text(cls));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                    _selectedSection = null; // Reset section when class changes
                    _selectedStudents.clear(); // Clear selected students
                    _availableStudents.clear(); // Clear available students
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                validator: (value) =>
                    value == null ? 'Please select a class' : null,
              ),
              const SizedBox(height: 16),

              // Section Dropdown
              const Text(
                'Section',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSection,
                items: _sections.map((sec) {
                  return DropdownMenuItem(value: sec, child: Text(sec));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value;
                    _selectedStudents.clear(); // Clear selected students
                  });
                  _loadStudents(); // Load students for new section
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                validator: (value) =>
                    value == null ? 'Please select a section' : null,
              ),
              const SizedBox(height: 16),

              // Student Multi-select section
              const Text(
                'Select Students',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Show loading indicator while loading students
              if (_isLoadingStudents)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Loading students...'),
                      ],
                    ),
                  ),
                )
              else if (_availableStudents.isEmpty &&
                  _selectedClass != null &&
                  _selectedSection != null)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No students found for the selected class and section.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (_availableStudents.isNotEmpty) ...[
                // Select All checkbox
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: allSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedStudents = List.from(_availableStudents);
                            } else {
                              _selectedStudents.clear();
                            }
                          });
                        },
                      ),
                      const Text(
                        'Select All',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Students list with checkboxes
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _availableStudents.map((student) {
                        return CheckboxListTile(
                          title: Text(student),
                          value: _selectedStudents.contains(student),
                          onChanged: (isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                _selectedStudents.add(student);
                              } else {
                                _selectedStudents.remove(student);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Show selected count
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected: ${_selectedStudents.length} of ${_availableStudents.length} students',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Please select class and section to load students.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Recipient type: Radio buttons
              const Text(
                'Send To',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                children: ['Only Students', 'Only Parents', 'Both'].map((type) {
                  return RadioListTile(
                    title: Text(type),
                    value: type,
                    groupValue: _recipientType,
                    onChanged: (value) {
                      setState(() => _recipientType = value!);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Message Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Message Title',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Exam Reminder',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter title'
                    : null,
              ),
              const SizedBox(height: 16),

              // Message Body
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter message'
                    : null,
              ),
              const SizedBox(height: 24),

              // Modify the send button to show different text based on mode
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_useManualToken &&
                              _manualTokenController.text.isNotEmpty) ||
                          (!_useManualToken && _selectedStudents.isNotEmpty)
                      ? _sendMessage
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_useManualToken &&
                                _manualTokenController.text.isNotEmpty) ||
                            (!_useManualToken && _selectedStudents.isNotEmpty)
                        ? Colors.green
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _useManualToken
                        ? (_manualTokenController.text.isEmpty
                            ? 'Enter FCM token to send message'
                            : 'Send Message with Manual Token')
                        : (_selectedStudents.isEmpty
                            ? 'Select students to send message'
                            : 'Send Message & Notify (${_selectedStudents.length} students)'),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
