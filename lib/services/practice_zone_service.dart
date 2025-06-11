import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches subjects for a specific grade in a school
  Future<Map<String, dynamic>> fetchSubjects(
      String schoolName, String grade) async {
    try {
      // Reference to the "practice" collection and the specific school document
      DocumentSnapshot schoolDoc =
          await _firestore.collection('practice').doc(schoolName).get();

      if (schoolDoc.exists) {
        // Get data for the specific grade
        Map<String, dynamic>? schoolData =
            schoolDoc.data() as Map<String, dynamic>?;
        return schoolData?[grade] ?? {};
      } else {
        print("School document not found.");
        return {};
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchTopics(
      String schoolName, String grade, String subject) async {
    try {
      // Reference to the "practice" collection and the specific school document
      DocumentSnapshot schoolDoc =
          await _firestore.collection('practice').doc(schoolName).get();

      if (schoolDoc.exists) {
        // Get data for the specific grade
        Map<String, dynamic>? schoolData =
            schoolDoc.data() as Map<String, dynamic>?;
        Map<String, dynamic>? gradeData =
            schoolData?[grade] as Map<String, dynamic>?;
        return gradeData?[subject] ?? {};
      } else {
        print("School document not found.");
        return {};
      }
    } catch (e) {
      print("Error fetching subjects: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getProgressDetails(
      String studentId) async {
    try {
      // Reference to the 'progress' collection
      CollectionReference progressCollection = _firestore
          .collection('students')
          .doc(studentId)
          .collection('progress');

      // Fetch all documents
      QuerySnapshot progressSnapshot = await progressCollection.get();

      // Map documents into a list of Maps
      return progressSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching progress details: $e');
      return [];
    }
  }

  // Fetch quizResults details for a specific student
  Future<List<Map<String, dynamic>>> getQuizResultsDetails(
      String studentId) async {
    try {
      // Reference to the 'quizResults' collection
      CollectionReference quizResultsCollection = _firestore
          .collection('students')
          .doc(studentId)
          .collection('quizResults');

      // Fetch all documents
      QuerySnapshot quizResultsSnapshot = await quizResultsCollection.get();

      // Map documents into a list of Maps
      return quizResultsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching quizResults details: $e');
      return [];
    }
  }
}
