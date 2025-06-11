import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'fillups_page.dart';
import 'vocal_page.dart';

import '../services/TestService.dart';
import 'mcq_page2.dart';
import '../services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  TasksScreenState createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final TestService _testService = TestService();
  List<Map<String, dynamic>> _taskItems = [];
  final List<Map<String, dynamic>> _recentTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final tests = await _testService.getTestsForClassAndSection();
      final userId = await AuthService.getUserId();
      // For each test, get the student's status from test_status
      for (final test in tests) {
        final testId = test['testId']?.toString() ?? '';
        if (testId.isNotEmpty && userId != null) {
          final statusDoc = await FirebaseFirestore.instance
              .collection('test_status')
              .doc('${testId}_$userId')
              .get();
          if (statusDoc.exists && statusDoc.data() != null) {
            test['status'] = statusDoc.data()!['status'] ?? test['status'];
          }
        }
      }

      // Convert tests to recent tasks format for upcoming tasks section
      final recentTasks = tests
          .where(
              (test) => test['status']?.toString().toLowerCase() != 'completed')
          .map((test) {
        final testDate = test['date'] as Timestamp?;
        final dueDate = testDate != null
            ? DateFormat('MMM dd, yyyy').format(testDate.toDate())
            : 'Test Available';

        // Normalize subject name
        String subject = test['subject']?.toString() ?? 'Unknown Subject';
        if (subject.toLowerCase() == 'computerscience' ||
            subject.toLowerCase() == 'computer') {
          subject = 'Computer Science';
        }

        return {
          'title': test['testName']?.toString() ??
              '${test['subject']?.toString() ?? 'Test'}',
          'subject': subject,
          'dueDate': dueDate,
          'status': test['status']?.toString() ?? 'pending',
          'color': _getSubjectColor(subject),
          'testId': test['testId']?.toString() ?? '',
          'date': testDate,
          'time': test['time']?.toString() ?? '',
          'duration': test['duration'] ?? 0,
          'maxMarks': test['maxMarks'] ?? 0,
          'type': test['type']?.toString().toLowerCase() ?? 'multiplechoice',
          'description': test['description']?.toString() ?? '',
        };
      }).toList();

      // Sort recent tasks by date
      recentTasks.sort((a, b) {
        final dateA = a['date'] as Timestamp?;
        final dateB = b['date'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

      // Group tests by subject for task items
      final Map<String, List<Map<String, dynamic>>> subjectGroups = {};
      for (var test in tests) {
        // Normalize subject name
        String subject = test['subject']?.toString() ?? 'Unknown Subject';
        if (subject.toLowerCase() == 'computerscience' ||
            subject.toLowerCase() == 'computer') {
          subject = 'Computer Science';
        }

        if (!subjectGroups.containsKey(subject)) {
          subjectGroups[subject] = [];
        }
        subjectGroups[subject]!.add(test);
      }

      // Create task items from grouped tests
      final taskItems = subjectGroups.entries.map((entry) {
        final subject = entry.key;
        final subjectTests = entry.value;

        // Calculate subject statistics
        final totalTests = subjectTests.length;
        final completedTests = subjectTests.where((test) {
          final status = test['status']?.toString().toLowerCase();
          return status == 'completed';
        }).length;

        // Get pending tests (not completed)
        final pendingTests = subjectTests.where((test) {
          final status = test['status']?.toString().toLowerCase();
          return status != 'completed';
        }).toList();

        // Get recent tests for this subject
        final recentSubjectTests = subjectTests.map((test) {
          final testDate = test['date'] as Timestamp?;
          return {
            'title': test['testName']?.toString() ??
                '${test['subject']?.toString() ?? 'Test'}',
            'subject': subject,
            'status': test['status']?.toString() ?? 'pending',
            'date': testDate,
            'time': test['time']?.toString() ?? '',
            'testId': test['testId']?.toString() ?? '',
            'type': test['type']?.toString().toLowerCase() ?? 'multiplechoice',
            'duration': test['duration'] ?? 0,
            'maxMarks': test['maxMarks'] ?? 0,
            'description': test['description']?.toString() ?? '',
          };
        }).toList();

        return {
          'title': subject,
          'subtitle': 'Tests and Assignments',
          'icon': _getSubjectIcon(subject),
          'color': _getSubjectColor(subject),
          'progress': totalTests == 0 ? 0.0 : completedTests / totalTests,
          'tasks': totalTests,
          'completed': completedTests,
          'upcoming': pendingTests.length,
          'recentTests': recentSubjectTests,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _recentTasks.clear();
          _recentTasks.addAll(recentTasks);
          _taskItems = taskItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSubjectIcon(String subject) {
    if (subject.isEmpty) return 'https://img.icons8.com/isometric/50/book.png';

    switch (subject.toLowerCase()) {
      case 'mathematics':
        return 'https://img.icons8.com/isometric/50/calculator.png';
      case 'science':
        return 'https://img.icons8.com/isometric/50/test-tube.png';
      case 'english':
        return 'https://img.icons8.com/isometric/50/literature.png';
      case 'history':
        return 'https://img.icons8.com/isometric/50/globe.png';
      case 'computer science':
      case 'computerscience':
      case 'computer':
        return 'https://img.icons8.com/isometric/50/laptop.png';
      default:
        return 'https://img.icons8.com/isometric/50/book.png';
    }
  }

  Color _getSubjectColor(String subject) {
    if (subject.isEmpty) return Colors.grey;

    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Colors.blue;
      case 'science':
        return Colors.green;
      case 'english':
        return Colors.purple;
      case 'history':
        return Colors.orange;
      case 'computer science':
      case 'computerscience':
      case 'computer':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            const Text(
              'Your Tasks Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track and manage your academic tasks',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming tasks section
            _buildUpcomingTasks(),
            const SizedBox(height: 32),

            // All subjects section
            const Text(
              'Tasks by Subject',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _taskItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subject_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No subjects available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _taskItems.length,
                    itemBuilder: (context, index) {
                      final item = _taskItems[index];
                      return _buildTaskCard(item, context);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text(
            'Upcoming Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: _recentTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming tasks',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentTasks.length,
                  itemBuilder: (context, index) {
                    final item = _recentTasks[index];
                    bool isCompleted =
                        item['status']?.toString().toLowerCase() == 'completed';

                    return GestureDetector(
                      onTap: () async {
                        if (isCompleted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('This test has already been completed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final testType =
                            item['type']?.toString().toLowerCase() ??
                                'multiplechoice';
                        final Map<String, dynamic> subjectData = {
                          'title': item['subject'] ?? 'Unknown Subject',
                          'color': _getSubjectColor(item['subject'] ?? ''),
                        };
                        final Map<String, dynamic> topicData = {
                          'title': item['title'] ?? 'Untitled Test',
                          'testId': item['testId'] ?? '',
                          'duration': item['duration'] ?? 0,
                          'maxMarks': item['maxMarks'] ?? 0,
                          'time': item['time'] ?? '',
                          'date': item['date'],
                          'description': item['description'] ?? '',
                          'type': testType,
                        };
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          final testDetails = await _testService
                              .getTestDetails(item['testId'] ?? '');
                          Navigator.pop(context); // Remove loading dialog
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => McqPage(
                                subjectData: subjectData,
                                topicData: {...topicData, ...?testDetails},
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadTests();
                          }
                        } catch (e) {
                          Navigator.pop(context); // Remove loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to load test details: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: item['color'].withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']?.toString() ?? 'Untitled Task',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  item['subject']?.toString() ??
                                      'Unknown Subject',
                                  style: TextStyle(
                                    color: item['color'],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['dueDate']?.toString() ??
                                          'No due date',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (item['time'] != null &&
                                        item['time'].toString().isNotEmpty)
                                      Text(
                                        'Time: ${item['time']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green
                                        : item['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (item['status']?.toString() ?? 'pending')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> item, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToTask(item),
      child: Container(
        height: 200, // Increased height to prevent overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: item['progress'],
              backgroundColor: item['color'].withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(item['color']),
              minHeight: 8,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Image.network(
                            item['icon'],
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Progress text and percentage in a row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['completed']} of ${item['tasks']} tasks',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          '${(item['progress'] * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: item['color'],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(), // Add spacer to push task counts to bottom
                    // Task counts in a row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildTaskCount(
                            'Upcoming',
                            item['upcoming'],
                            item['color'],
                          ),
                        ),
                        Expanded(
                          child: _buildTaskCount(
                            'Completed',
                            item['completed'],
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTask(Map<String, dynamic> task) {
    // Show subject tasks dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${task['title']} Tasks'),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending Tasks Section
                if (task['upcoming'] > 0) ...[
                  const Text(
                    'Pending Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...task['recentTests']
                      .where((test) =>
                          test['status']?.toString().toLowerCase() !=
                          'completed')
                      .map((test) => _buildTaskListItem(test))
                      .toList(),
                ] else ...[
                  const Text(
                    'Pending Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNoTasksMessage('No pending tasks'),
                ],
                // Completed Tasks Section
                if (task['completed'] > 0) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Completed Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...task['recentTests']
                      .where((test) =>
                          test['status']?.toString().toLowerCase() ==
                          'completed')
                      .map((test) => _buildTaskListItem(test))
                      .toList(),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Completed Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNoTasksMessage('No completed tasks'),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTasksMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCount(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              label == 'Upcoming' ? 'Pending' : label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListItem(Map<String, dynamic> test) {
    bool isCompleted = test['status']?.toString().toLowerCase() == 'completed';
    final testType = test['type']?.toString().toLowerCase() ?? 'multiplechoice';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          testType == 'vocal'
              ? Icons.mic
              : testType == 'fillblanks'
                  ? Icons.edit
                  : Icons.list_alt,
          color: isCompleted ? Colors.green : Colors.blue,
        ),
        title: Text(
          test['title'] ?? 'Untitled Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(test['subject'] ?? 'Unknown Subject'),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: isCompleted
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This test has already been completed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            : () async {
                Navigator.pop(context);
                final Map<String, dynamic> subjectData = {
                  'title': test['subject'] ?? 'Unknown Subject',
                  'color': _getSubjectColor(test['subject'] ?? ''),
                };
                final Map<String, dynamic> topicData = {
                  'title': test['title'] ?? 'Untitled Test',
                  'testId': test['testId'] ?? '',
                  'duration': test['duration'] ?? 0,
                  'maxMarks': test['maxMarks'] ?? 0,
                  'time': test['time'] ?? '',
                  'date': test['date'],
                  'description': test['description'] ?? '',
                  'type': testType,
                };
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final testDetails =
                      await _testService.getTestDetails(test['testId'] ?? '');
                  Navigator.pop(context); // Remove loading dialog
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => McqPage(
                        subjectData: subjectData,
                        topicData: {...topicData, ...?testDetails},
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadTests();
                  }
                } catch (e) {
                  Navigator.pop(context); // Remove loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load test details: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
      ),
    );
  }
}

// Task detail screen that shows tasks for the selected subject
class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String subject;
  final String studentId;
  final Function(bool) onStatusChanged;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.subject,
    required this.studentId,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late bool _isCompleted;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Convert the status to boolean
    _isCompleted =
        widget.task['status']?.toString().toLowerCase() == 'completed';
  }

  Future<void> _updateTestStatus() async {
    setState(() => _isLoading = true);
    try {
      final testId = widget.task['testId'];
      if (testId == null) {
        throw Exception('Test ID not found');
      }

      final testService = TestService();
      await testService.updateTestStatus(
        testId: testId,
        studentId: widget.studentId,
        status: _isCompleted ? 'completed' : 'pending',
      );

      widget.onStatusChanged(_isCompleted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isCompleted
                ? 'Test marked as completed'
                : 'Test marked as pending'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update test status: $e'),
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
        title: Text(widget.task['title']?.toString() ?? 'Task Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task['title']?.toString() ?? 'Untitled Task',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task['description']?.toString() ??
                          'No description available',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${widget.task['dueDate']?.toString() ?? 'No due date'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.subject, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Subject: ${widget.subject}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isCompleted ? 'Completed' : 'Pending',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  _isCompleted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isCompleted,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _isCompleted = value);
                                  _updateTestStatus();
                                },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
