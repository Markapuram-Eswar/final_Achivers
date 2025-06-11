import 'package:cloud_firestore/cloud_firestore.dart';
import 'AttendanceService.dart';
import 'auth_service.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();

  Future<List<Map<String, dynamic>>> getStudentsByClass(String className, String section) async {
    try {
      final normalizedClass = _attendanceService.normalizeClassName(className);
      print('Fetching students for class: $normalizedClass, section: $section');
      
      // First try exact match
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('class', isEqualTo: normalizedClass)
          .where('section', isEqualTo: section)
          .get();

      // If no results, try with different class formats
      if (snapshot.docs.isEmpty) {
        print('No exact matches found, trying alternative formats...');
        
        // Try with 'th' suffix
        snapshot = await _firestore
            .collection('students')
            .where('class', isEqualTo: '${normalizedClass}th')
            .where('section', isEqualTo: section)
            .get();
            
        // If still no results, try with 'Class' prefix
        if (snapshot.docs.isEmpty) {
          snapshot = await _firestore
              .collection('students')
              .where('class', isEqualTo: 'Class $normalizedClass')
              .where('section', isEqualTo: section)
              .get();
        }
      }

      if (snapshot.docs.isEmpty) {
        print('No students found for class: $normalizedClass, section: $section');
        return [];
      }

      print('Found ${snapshot.docs.length} students');
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo'] ?? '',
          'class': data['class'] ?? normalizedClass,
          'section': data['section'] ?? section,
          'admissionNo': data['admissionNo'] ?? '',
          'parentName': data['parentName'] ?? '',
          'parentPhone': data['parentPhone'] ?? '',
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final snapshot = await _firestore.collection('students').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching all students: $e');
      return [];
    }
  }

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
      print('Error getting student profile: $e');
      rethrow;
    }
  }

  Future<void> updateStudentProfile({
    required String name,
    required String className,
    required String section,
    required String parentEmail,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || userType != 'student') {
        throw 'No logged-in student found.';
      }

      await _firestore.collection('students').doc(userId).update({
        'name': name.trim(),
        'class': className.trim(),
        'section': section.trim(),
        'parentEmail': parentEmail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating student profile: $e');
      rethrow;
    }
  }
}
