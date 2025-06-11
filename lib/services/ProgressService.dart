import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get progress data for all subjects
  Future<List<Map<String, dynamic>>> getProgressData({String? studentRollNo}) async {
    try {
      final userId = studentRollNo ?? await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get student document
      final studentDoc = await _firestore.collection('students').doc(userId).get();
      final studentData = studentDoc.data();

      if (studentData == null || !studentData.containsKey('subjects')) {
        return [];
      }

      final subjects = studentData['subjects'] as Map<String, dynamic>;
      List<Map<String, dynamic>> progressData = [];

      // Process each subject
      subjects.forEach((subject, data) {
        final subjectData = data as Map<String, dynamic>;
        final totalTests = subjectData['totalTests'] ?? 0;
        final completedTests = subjectData['completedTests'] ?? 0;
        
        // Calculate progress percentage
        final progress = totalTests > 0 ? completedTests / totalTests : 0.0;
        final percentage = (progress * 100).toStringAsFixed(1);

        // Get subject color based on subject name
        final color = _getSubjectColor(subject);
        
        // Get subject icon based on subject name
        final icon = _getSubjectIcon(subject);

        progressData.add({
          'subject': subject,
          'progress': progress,
          'percentage': percentage,
          'color': color,
          'icon': icon,
          'totalTests': totalTests,
          'completedTests': completedTests,
        });
      });

      return progressData;
    } catch (e) {
      print('Error getting progress data: $e');
      rethrow;
    }
  }

  // Get overall progress
  Future<Map<String, dynamic>> getOverallProgress({String? studentRollNo}) async {
    try {
      final progressData = await getProgressData(studentRollNo: studentRollNo);
      if (progressData.isEmpty) {
        return {
          'progress': 0.0,
          'percentage': '0.0',
          'totalTests': 0,
          'completedTests': 0,
        };
      }

      int totalTests = 0;
      int completedTests = 0;

      for (var subject in progressData) {
        totalTests += subject['totalTests'] as int;
        completedTests += subject['completedTests'] as int;
      }

      final progress = totalTests > 0 ? completedTests / totalTests : 0.0;
      final percentage = (progress * 100).toStringAsFixed(1);

      return {
        'progress': progress,
        'percentage': percentage,
        'totalTests': totalTests,
        'completedTests': completedTests,
      };
    } catch (e) {
      print('Error getting overall progress: $e');
      rethrow;
    }
  }

  // Get recent achievements
  Future<List<Map<String, dynamic>>> getRecentAchievements({String? studentRollNo}) async {
    try {
      final userId = studentRollNo ?? await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final studentDoc = await _firestore.collection('students').doc(userId).get();
      final studentData = studentDoc.data();

      if (studentData == null || !studentData.containsKey('subjects')) {
        return [];
      }

      final subjects = studentData['subjects'] as Map<String, dynamic>;
      List<Map<String, dynamic>> achievements = [];

      // Check for quiz master achievement
      int totalCompletedTests = 0;
      int totalTests = 0;
      subjects.forEach((subject, data) {
        totalCompletedTests += (data['completedTests'] ?? 0) as int;
        totalTests += (data['totalTests'] ?? 0) as int;
      });

      final overallPercentage = totalTests > 0 ? (totalCompletedTests / totalTests * 100).toStringAsFixed(1) : '0.0';

      if (totalCompletedTests >= 5) {
        achievements.add({
          'title': 'Quiz Master',
          'subtitle': '$overallPercentage% Overall Progress',
          'icon': Icons.quiz,
        });
      }

      // Check for perfect scores
      subjects.forEach((subject, data) {
        final tests = List<Map<String, dynamic>>.from(data['tests'] ?? []);
        final perfectScores = tests.where((test) => 
          test['status'] == 'completed' && 
          test['score'] == test['maxMarks']
        ).length;

        if (perfectScores > 0) {
          final subjectPercentage = tests.isNotEmpty ? 
            (perfectScores / tests.length * 100).toStringAsFixed(1) : '0.0';
          
          achievements.add({
            'title': 'Perfect Score',
            'subtitle': '$subjectPercentage% in $subject',
            'icon': Icons.star,
          });
        }
      });

      return achievements;
    } catch (e) {
      print('Error getting achievements: $e');
      rethrow;
    }
  }

  // Helper method to get subject color
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Colors.blue;
      case 'science':
        return Colors.green;
      case 'english':
        return Colors.purple;
      case 'social studies':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  // Helper method to get subject icon
  String _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return 'https://img.icons8.com/isometric/50/hygrometer.png';
      case 'science':
        return 'https://img.icons8.com/isometric/50/microscope.png';
      case 'english':
        return 'https://img.icons8.com/isometric/50/book-shelf.png';
      case 'social studies':
        return 'https://img.icons8.com/isometric/50/world-map.png';
      default:
        return 'https://img.icons8.com/isometric/50/book.png';
    }
  }
} 