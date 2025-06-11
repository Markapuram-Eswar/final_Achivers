import 'package:flutter/material.dart';
import 'subject_practice_page.dart';
import '../services/practice_zone_service.dart';
import '../services/ProfileService.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/text_book_service.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  PracticePageState createState() => PracticePageState();
}

class PracticePageState extends State<PracticePage> {
  final FirebaseService _practiceZoneService = FirebaseService();
  final ProfileService _profileService = ProfileService();

  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? errorMessage = '';

  List<Map<String, dynamic>> _practiceItems = [];
  final List<Map<String, dynamic>> _recentPractice = [
    {
      'title': 'Algebra Quiz',
      'subject': 'Mathematics',
      'date': 'Yesterday',
      'score': '85%',
      'color': Colors.blue,
    },
    {
      'title': 'Physics Formulas',
      'subject': 'Science',
      'date': '2 days ago',
      'score': '92%',
      'color': Colors.green,
    },
    {
      'title': 'Grammar Test',
      'subject': 'English',
      'date': '3 days ago',
      'score': '78%',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch student profile first
      final profileData = await ProfileService().getStudentProfile();
      setState(() => studentData = profileData);

      // Then fetch practice items using school/class from profile
      await _fetchPracticeItems();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPracticeItems() async {
    if (studentData == null) {
      setState(() => errorMessage = 'Student profile not loaded');
      return;
    }

    final school = studentData!['school'].toString();
    final grade = studentData!['class'].toString();

    // Print for debugging
    print('Student school: $school, class: $grade');

    if (school == null || grade == null) {
      setState(() => errorMessage = 'School or class missing in profile');
      return;
    }

    try {
      final subjects = await _practiceZoneService.fetchSubjects(school, grade);

      print('Subjects: ${subjects['Mathematics']}');

      if (subjects == null || subjects.isEmpty) {
        setState(() => errorMessage = 'No subjects found for your class');
        return;
      }

      print('Fetched ${subjects.length} subjects: ${subjects.keys.join(', ')}');

      final List<Map<String, dynamic>> items = [];

      subjects.forEach((subjectName, subjectData) {
        // Subject data is already a Map<String, dynamic>
        List<Map<String, dynamic>> topics = [];

        if (subjectData is Map) {
          // Iterate through each topic in the subject
          subjectData.forEach((topicName, topicContent) {
            // Add the topic as a map with its name and content
            topics.add({
              'name': topicName,
              'data':
                  topicContent, // Stores the topic content (blanks, mcq, etc.)
            });
          });
        }

        // If no topics found, use default text
        print('Subject data ash: ${subjectData}');
        items.add({
          'title': subjectName,
          'subtitle': topics ?? 'Practice questions',
          'icon': subjectData['icon'] ??
              'https://img.icons8.com/isometric/50/book-shelf.png',
          'color': _getSubjectColor(subjectName),
          'progress': _parseDouble(subjectData['progress']),
          'questions': _parseInt(subjectData['questions']),
          'completed': _parseInt(subjectData['completed']),
        });
      });

      setState(() {
        _practiceItems = items;
        errorMessage = null;
      });
    } catch (e) {
      setState(() => errorMessage = 'Error loading subjects: ${e.toString()}');
    }
  }

// Safe parsing helpers
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

// Consistent color generator
  Color _getSubjectColor(String subject) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
    ];
    final index = subject.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Practice Zone', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section

            // Recent practice section

            const SizedBox(height: 24),

            // Practice by subject section
            if (_practiceItems.isNotEmpty) ...[
              const Text(
                'Practice by Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._practiceItems.map((item) => _buildPracticeCard(item)),
              const SizedBox(height: 24),
            ],

            // Quick practice section
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectPracticePage(
                    subjectData: item, grade: studentData!['class']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        item['icon'],
                        width: 30,
                        height: 30,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.menu_book),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'], // Fixed: use item['title']
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item['subtitle']
                                .map((topic) => topic['name'])
                                .join(', '),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: item['progress'],
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(item['color']),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item['completed']} / ${item['questions']} questions completed',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectPracticePage(
                                subjectData: item,
                                grade: studentData!['class']),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item['color'],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Practice'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPracticeButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepOrange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
