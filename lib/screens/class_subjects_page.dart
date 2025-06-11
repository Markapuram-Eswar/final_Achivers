import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/textbook_service.dart';
import 'textbook_page.dart';

class ClassSubjectsPage extends StatefulWidget {
  final String classNumber;

  const ClassSubjectsPage({
    super.key,
    required this.classNumber,
  });

  @override
  State<ClassSubjectsPage> createState() => _ClassSubjectsPageState();
}

class _ClassSubjectsPageState extends State<ClassSubjectsPage> {
  final TextbookService _textbookService = TextbookService();
  Map<String, dynamic> _subjects = {};
  bool _isLoading = true;
  String? _error;

  // Subject colors
  final Map<String, Color> _subjectColors = {
    'Language Learning': Colors.blue,
    'Science': Colors.green,
    'Mathematics': Colors.purple,
    'Social Studies': Colors.orange,
    'English': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _textbookService.streamClassSubjects(widget.classNumber).listen(
        (subjects) {
          if (mounted) {
            setState(() {
              _subjects = subjects;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class ${widget.classNumber}'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
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
                        onPressed: _loadSubjects,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects.keys.elementAt(index);
                    final topics = _subjects[subject] as Map<String, dynamic>;
                    final color = _subjectColors[subject] ?? Colors.blue;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Navigate to the first topic of this subject
                          final firstTopic = topics.keys.first;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TextBookAudioPage(
                                
                                subjectData: {
                                  'title': subject,
                                  'color': color,
                                },
                                topicData: {
                                  'title': firstTopic,
                                  'class': widget.classNumber,
                                },
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getSubjectIcon(subject),
                                    color: color,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      subject,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${topics.length} Topics',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Language Learning':
        return Icons.language;
      case 'Science':
        return Icons.science;
      case 'Mathematics':
        return Icons.calculate;
      case 'Social Studies':
        return Icons.public;
      case 'English':
        return Icons.menu_book;
      default:
        return Icons.school;
    }
  }
}
