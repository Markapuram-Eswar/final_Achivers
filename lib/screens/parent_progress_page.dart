import 'package:flutter/material.dart';
import '../services/ProgressService.dart';

class ProgressPage extends StatefulWidget {
  final Map<String, dynamic> child;
  const ProgressPage({super.key, required this.child});

  @override
  State<ProgressPage> createState() => _ProgressZonePageState();
}

class _ProgressZonePageState extends State<ProgressPage> {
  final ProgressService _progressService = ProgressService();
  List<Map<String, dynamic>> _progressData = [];
  Map<String, dynamic> _overallProgress = {
    'progress': 0.0,
    'totalTests': 0,
    'completedTests': 0,
  };
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;
  String? _error;

  String get _studentRollNo {
    return widget.child['rollNumber'] ?? widget.child['rollNo'] ?? widget.child['id'] ?? '';
  }

  String get _studentName {
    return widget.child['name'] ?? widget.child['fullName'] ?? 'Unknown';
  }

  String get _studentClass {
    return widget.child['class'] ?? '';
  }

  String get _studentSection {
    return widget.child['section'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    if (_studentRollNo.isEmpty) {
      setState(() => _error = 'No student selected.');
    } else {
      _loadProgressData();
    }
  }

  Future<void> _loadProgressData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _progressService.getProgressData(studentRollNo: _studentRollNo),
        _progressService.getOverallProgress(studentRollNo: _studentRollNo),
        _progressService.getRecentAchievements(studentRollNo: _studentRollNo),
      ]);

      if (mounted) {
        setState(() {
          _progressData = results[0] as List<Map<String, dynamic>>;
          _overallProgress = results[1] as Map<String, dynamic>;
          _achievements = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading progress data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading progress: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Progress Zone', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.amber,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Progress Zone', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.amber,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Zone', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgressData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child details card
              Card(
                color: Colors.amber[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(_studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Roll No: $_studentRollNo\nClass: $_studentClass  Section: $_studentSection'),
                ),
              ),
              const Text(
                'Your Learning Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your progress across different subjects',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Progress cards
              if (_progressData.isEmpty)
                const Center(
                  child: Text('No subjects found'),
                )
              else
                ..._progressData.map((data) => _buildProgressCard(data)),

              const SizedBox(height: 24),

              // Overall progress section
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _overallProgress['progress'],
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '	${(_overallProgress['progress'] * 100).toInt()}% Completed',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        Text(
                          '${_overallProgress['percentage']}% Complete',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Achievements section
              if (_achievements.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Recent Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _achievements
                            .map(
                              (achievement) => _buildAchievementBadge(
                                achievement['title'],
                                achievement['subtitle'],
                                achievement['icon'],
                              ),
                            )
                            .toList(),
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

  Widget _buildProgressCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: data['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              data['icon'],
              width: 30,
              height: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: data['progress'],
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(data['color']),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['percentage']}% Complete',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, String subtitle, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.amber,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
