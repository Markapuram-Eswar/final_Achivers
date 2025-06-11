import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> storeQuizResult({
    required String studentId,
    required String subjectId,
    required String subjectName,
    required String topicId,
    required String topicName,
    required int score,
    required int totalQuestions,
    required List<Map<String, dynamic>> questionResults,
    required Duration timeTaken,
  }) async {
    try {
      final CollectionReference quizResultsRef = _firestore
          .collection('students')
          .doc(studentId)
          .collection('quizResults');

      await quizResultsRef.add({
        'subjectId': subjectId,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': topicName,
        'score': score,
        'totalQuestions': totalQuestions,
        'percentage': (score / totalQuestions * 100).round(),
        'timestamp': FieldValue.serverTimestamp(),
        'timeTakenSeconds': timeTaken.inSeconds,
        'questionResults': questionResults,
      });

      return true;
    } catch (e) {
      print('Error saving quiz result: $e');
      return false;
    }
  }
}