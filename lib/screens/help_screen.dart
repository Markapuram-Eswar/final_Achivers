import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/help_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();
  final HelpService _helpService = HelpService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _helpRequests = [];

  @override
  void initState() {
    super.initState();
    _loadHelpRequests();
  }

  void _loadHelpRequests() {
    _helpService.getHelpRequests().listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            _helpRequests = snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    })
                .toList();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All fields are required and must be valid.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _helpRequests = [];
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _helpService.submitHelpRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        issue: _issueController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your request has been submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _issueController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              try {
                await _helpService.printHelpRequests();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Check console for help requests data'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please fill out the form below and our support team will get back to you as soon as possible.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _issueController,
                    decoration: const InputDecoration(
                      labelText: 'Describe your issue',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your issue';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide more details about your issue';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_helpRequests.isNotEmpty) ...[
              const Text(
                'Your Previous Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _helpRequests.length,
                itemBuilder: (context, index) {
                  final request = _helpRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(
                        request['issue'].toString().split('\n').first,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Status: ${request['status']} • ${_formatDate(request['createdAt'])}',
                        style: TextStyle(
                          color: _getStatusColor(request['status']),
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Issue: ${request['issue']}'),
                              const SizedBox(height: 8),
                              Text('Email: ${request['email']}'),
                              const SizedBox(height: 8),
                              Text(
                                  'Submitted: ${_formatDate(request['createdAt'])}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I update my profile information?',
              'You can update your profile information by going to the Edit Profile section in your account settings.',
            ),
            _buildFaqItem(
              'How can I contact my teacher?',
              'You can contact your teacher through the Contact Teacher section in the parent dashboard.',
            ),
            _buildFaqItem(
              'Where can I view my payment history?',
              'Your payment history is available in the Fee Payments section of the parent dashboard.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    return 'N/A';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
