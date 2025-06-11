import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to normalize class name
  String _normalizeClassName(String className) {
    // Remove "Class" prefix if present
    String normalized = className.replaceAll('Class ', '');

    // Remove "th", "st", "nd", "rd" suffixes if present
    normalized = normalized.replaceAll(RegExp(r'(th|st|nd|rd)$'), '');

    // Convert to number and back to string to ensure consistent format
    try {
      final number = int.parse(normalized);
      return number.toString();
    } catch (e) {
      return normalized;
    }
  }

  // Get students by class and section
  Future<List<Map<String, dynamic>>> getStudentsByClassAndSection(
    String className,
    String section,
  ) async {
    try {
      final normalizedClass = _normalizeClassName(className);

      // Query with both original and normalized class names
      final QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('section', isEqualTo: section)
          .get();

      // Filter results to match either original or normalized class name
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final studentClass = data['class']?.toString() ?? '';
        return _normalizeClassName(studentClass) == normalizedClass;
      });

      return filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'rollNo': data['rollNo'] ?? '',
          'class': data['class'] ?? '',
          'section': data['section'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      rethrow;
    }
  }

  // Save assessment details for a student
  Future<void> saveAssessmentDetails({
    required String studentId,
    required String examType,
    required String subject,
    required int marks,
    required String grade,
    required String className,
    required String section,
  }) async {
    try {
      final normalizedClass = _normalizeClassName(className);

      final assessmentData = {
        'examType': examType,
        'subject': subject,
        'marks': marks,
        'grade': grade,
        'class': normalizedClass,
        'section': section,
        // 'date': FieldValue.serverTimestamp(),
      };

      // Get the student document
      final studentRef = _firestore.collection('students').doc(studentId);
      final studentDoc = await studentRef.get();
      final studentData = studentDoc.data() ?? {};

      // Get existing assessments or initialize empty list
      List<Map<String, dynamic>> assessments =
          List<Map<String, dynamic>>.from(studentData['assessments'] ?? []);

      // Add new assessment
      assessments.add(assessmentData);

      // Update student document with new assessment
      await studentRef.update({
        'assessments': assessments,
      });

      // Update the student's subject progress
      await _updateSubjectProgress(studentId, subject, marks);
    } catch (e) {
      print('Error saving assessment: $e');
      rethrow;
    }
  }

  // Update subject progress in student document
  Future<void> _updateSubjectProgress(
    String studentId,
    String subject,
    int marks,
  ) async {
    try {
      final studentRef = _firestore.collection('students').doc(studentId);
      final studentDoc = await studentRef.get();
      final studentData = studentDoc.data();

      if (studentData != null && studentData.containsKey('subjects')) {
        final subjects = Map<String, dynamic>.from(studentData['subjects']);

        if (subjects.containsKey(subject)) {
          final subjectData = Map<String, dynamic>.from(subjects[subject]);
          final totalTests = (subjectData['totalTests'] ?? 0) + 1;
          final totalMarks = (subjectData['totalMarks'] ?? 0) + marks;
          final averageMarks = totalMarks / totalTests;

          subjects[subject] = {
            ...subjectData,
            'totalTests': totalTests,
            'totalMarks': totalMarks,
            'averageMarks': averageMarks,
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          await studentRef.update({'subjects': subjects});
        }
      }
    } catch (e) {
      print('Error updating subject progress: $e');
      rethrow;
    }
  }

  // Get assessment history for a student
  Future<List<Map<String, dynamic>>> getStudentAssessments(
      String studentId) async {
    try {
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();

      final studentData = studentDoc.data();
      if (studentData == null || !studentData.containsKey('assessments')) {
        return [];
      }

      final assessments =
          List<Map<String, dynamic>>.from(studentData['assessments'] ?? []);

      // Sort assessments by date in descending order
      assessments.sort((a, b) {
        final aDate = a['date'] as Timestamp?;
        final bDate = b['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      return assessments
          .map((assessment) => {
                ...assessment,
                'date': (assessment['date'] as Timestamp).toDate(),
              })
          .toList();
    } catch (e) {
      print('Error getting assessments: $e');
      rethrow;
    }
  }
}
