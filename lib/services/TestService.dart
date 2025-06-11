import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class TestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new test
  Future<void> createTest({
    required String subject,
    required String classLevel,
    required String section,
    required DateTime date,
    required String time,
    required int duration,
    required int maxMarks,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || (userType != 'teacher' && userType != 'admin')) {
        throw 'Unauthorized: Only teachers or admins can create tests.';
      }

      print('Creating test for class: $classLevel, section: $section');

      // Step 1: Add the test
      final testDocRef = await _firestore.collection('tests').add({
        'subject': subject.trim(),
        'class': classLevel.trim(),
        'section': section.trim(),
        'date': Timestamp.fromDate(date),
        'time': time.trim(),
        'duration': duration,
        'maxMarks': maxMarks,
        'questions': questions,
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final testId = testDocRef.id;
      print('Test created with ID: $testId');

      // Step 2: Fetch matching students with different class formats
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('section', isEqualTo: section.trim())
          .get();

      print('Found ${studentsSnapshot.docs.length} students in section $section');

      // Filter students by class format
      final matchingStudents = studentsSnapshot.docs.where((doc) {
        final studentData = doc.data();
        final studentClass = studentData['class']?.toString().trim() ?? '';
        
        // Handle different class formats
        final normalizedStudentClass = studentClass.replaceAll(RegExp(r'[^0-9]'), '');
        final normalizedTestClass = classLevel.replaceAll(RegExp(r'[^0-9]'), '');
        
        return normalizedStudentClass == normalizedTestClass;
      }).toList();

      print('Found ${matchingStudents.length} students matching class $classLevel');

      if (matchingStudents.isEmpty) {
        throw 'No students found in class $classLevel section $section';
      }

      // Step 3: Update each student doc with the test info under subjects
      for (var doc in matchingStudents) {
        try {
        final studentRef = doc.reference;
          final studentData = doc.data();
          print('Processing student: ${studentData['name'] ?? 'Unknown'}');

          // Get existing subjects or initialize empty map
          Map<String, dynamic> subjects = Map<String, dynamic>.from(studentData['subjects'] ?? {});
          
          // Get existing tests for this subject or initialize empty list
          List<dynamic> subjectTests = List<dynamic>.from(subjects[subject]?['tests'] ?? []);
          
          // Add new test
          subjectTests.add({
              'testId': testId,
              'subject': subject.trim(),
              'testName': '$subject Test',
              'status': 'pending',
            'date': Timestamp.fromDate(date),
            'time': time.trim(),
            'duration': duration,
            'maxMarks': maxMarks,
          });

          // Update the subject's tests
          subjects[subject] = {
            'tests': subjectTests,
            'totalTests': subjectTests.length,
            'completedTests': subjectTests.where((test) => test['status'] == 'completed').length,
          };

          // Update student document
          await studentRef.update({
            'subjects': subjects,
          });
          print('Successfully updated test for student: ${studentData['name'] ?? 'Unknown'}');
        } catch (e) {
          print('Error updating student ${doc.id}: $e');
          // Continue with next student even if one fails
          continue;
        }
      }
    } catch (e) {
      print('Error in createTest: $e');
      rethrow;
    }
  }

  // Get all tests created by current user (optional, for listing)
  Future<List<Map<String, dynamic>>> getMyTests() async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || (userType != 'teacher' && userType != 'admin')) {
        throw 'Unauthorized: Only teachers or admins can view their tests.';
      }

      final snapshot = await _firestore
          .collection('tests')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStudentTests() async {
    final userId = await AuthService.getUserId();
    final userType = await AuthService.getUserType();

    if (userId == null || userType != 'student') {
      throw 'Unauthorized: Only students can fetch their tests.';
    }

    // Get the student's class and section
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null ||
        !userData.containsKey('class') ||
        !userData.containsKey('section')) {
      throw 'User data is incomplete.';
    }

    final classLevel = userData['class'];
    final section = userData['section'];

    // Fetch tests matching class and section
    final querySnapshot = await _firestore
        .collection('tests')
        .where('class', isEqualTo: classLevel)
        .where('section', isEqualTo: section)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getTestsForClassAndSection() async {
    final userId = await AuthService.getUserId();
    final userType = await AuthService.getUserType();

    if (userId == null || userType != 'student') {
      throw 'Unauthorized: Only students can fetch profile tests.';
    }

    final userDoc = await _firestore.collection('students').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null || !userData.containsKey('subjects')) {
      return []; // No subjects/tests assigned
    }

    // Get all subjects and their tests
    final Map<String, dynamic> subjects = userData['subjects'];
    List<Map<String, dynamic>> allTests = [];

    // Flatten all tests from all subjects
    subjects.forEach((subject, data) {
      final List<dynamic> subjectTests = data['tests'] ?? [];
      allTests.addAll(subjectTests.map((test) => {
        ...test,
        'subject': subject,
        'subjectData': {
          'totalTests': data['totalTests'] ?? 0,
          'completedTests': data['completedTests'] ?? 0,
        },
      }));
    });

    return allTests;
  }

  // Update test status for a student
  Future<void> updateTestStatus({
    required String testId,
    required String studentId,
    required String status,
    int? score,
    int? totalQuestions,
    double? percentageScore,
  }) async {
    try {
      // Get the student ID from AuthService
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get the student document
      final studentDoc = await _firestore.collection('students').doc(userId).get();
      final studentData = studentDoc.data();
      
      if (studentData == null || !studentData.containsKey('subjects')) {
        throw Exception('Student data not found');
      }

      // Get the subjects map
      Map<String, dynamic> subjects = Map<String, dynamic>.from(studentData['subjects']);
      
      // Find the subject containing the test
      String? subjectWithTest;
      for (var entry in subjects.entries) {
        final subjectTests = List<Map<String, dynamic>>.from(entry.value['tests'] ?? []);
        if (subjectTests.any((test) => test['testId'] == testId)) {
          subjectWithTest = entry.key;
          break;
        }
      }

      if (subjectWithTest == null) {
        throw Exception('Test not found in student subjects');
      }

      // Update the test in the subject's tests array
      List<Map<String, dynamic>> subjectTests = List<Map<String, dynamic>>.from(subjects[subjectWithTest]['tests']);
      final testIndex = subjectTests.indexWhere((test) => test['testId'] == testId);
      
      if (testIndex == -1) {
        throw Exception('Test not found in subject');
      }

      // Update the test status and score
      subjectTests[testIndex]['status'] = status;
      if (score != null) {
        subjectTests[testIndex]['score'] = score;
      }

      // Update the subject's tests array
      subjects[subjectWithTest]['tests'] = subjectTests;
      
      // Update completed tests count
      subjects[subjectWithTest]['completedTests'] = 
          subjectTests.where((test) => test['status'] == 'completed').length;

      // Update the student document
      await _firestore.collection('students').doc(userId).update({
        'subjects': subjects,
      });

    } catch (e) {
      print('Error updating test status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTestDetails(String testId) async {
    try {
      final doc = await _firestore.collection('tests').doc(testId).get();
      return doc.data();
    } catch (e) {
      print('Error getting test details: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStudentTestResults(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      final data = doc.data();
      if (data == null || !data.containsKey('subjects')) {
        return [];
      }
      
      final subjects = data['subjects'] as Map<String, dynamic>;
      List<Map<String, dynamic>> allTests = [];
      
      subjects.forEach((subject, subjectData) {
        final tests = List<Map<String, dynamic>>.from(subjectData['tests'] ?? []);
        allTests.addAll(tests.map((test) => {
          ...test,
          'subject': subject,
        }));
      });
      
      return allTests;
    } catch (e) {
      print('Error getting student test results: $e');
      rethrow;
    }
  }

  Future<void> saveTestResult({
    required String testId,
    required String studentId,
    required Map<String, dynamic> resultData,
  }) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'testResults.$testId': resultData,
      });
    } catch (e) {
      print('Error saving test result: $e');
      rethrow;
    }
  }
}
