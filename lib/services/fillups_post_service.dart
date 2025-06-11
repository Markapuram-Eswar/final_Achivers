import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch student profile details
  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || userType != 'student') {
        throw 'No logged-in student found.';
      }

      final doc = await _firestore.collection('students').doc(userId).get();

      if (!doc.exists) {
        throw 'Student profile not found.';
      }

      return doc.data()!;
    } catch (e) {
      rethrow;
    }
  }
}

class EditProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch student profile details
  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || userType != 'student') {
        throw 'No logged-in student found.';
      }

      final doc = await _firestore.collection('students').doc(userId).get();

      if (!doc.exists) {
        throw 'Student profile not found.';
      }

      return doc.data()!;
    } catch (e) {
      rethrow;
    }
  }

  // Update student profile details
  Future<void> updateStudentProfile({
    required String fullName,
    required String studentClass,
    required String section,
    required String parentEmail,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || userType != 'student') {
        throw 'No logged-in student found.';
      }

      await _firestore.collection('students').doc(userId).set({
        'fullName': fullName.trim(),
        'class': studentClass.trim(),
        'section': section.trim(),
        'parentEmail': parentEmail.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}

class FillupsPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFillupsResult({
    required String userId,
    required String subjectId,
    required String topicId,
    required String subjectName,
    required String topicName,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int percentage,
    required int timeSpent,
  }) async {
    final progressData = {
      'userId': userId,
      'subjectId': subjectId,
      'topicId': topicId,
      'subjectName': subjectName,
      'topicName': topicName,
      'activityType': 'fillups',
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'timeSpent': timeSpent,
      'completedAt': FieldValue.serverTimestamp(),
      'isCompleted': true,
    };

    // Save to students collection with subcollection structure
    await _firestore
        .collection('students')
        .doc(userId)
        .collection('progress')
        .doc('${subjectId}_${topicId}_fillups')
        .set(progressData, SetOptions(merge: true));

    // Also update the main student document with latest activity
    await _firestore
        .collection('students')
        .doc(userId)
        .set({
      'lastActivity': {
        'type': 'fillups',
        'subjectId': subjectId,
        'topicId': topicId,
        'score': score,
        'percentage': percentage,
        'completedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }
}
