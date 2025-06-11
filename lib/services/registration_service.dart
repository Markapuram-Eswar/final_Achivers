import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Register Student
  Future<void> registerStudent({
    required String rollNumber,
    required String name,
    required String className,
    required String section,
    String? parentEmail,
    String? classTeacherId,
    required String studentFCMToken,
  }) async {
    try {
      // Check if student already exists
      final existingStudent =
          await _firestore.collection('students').doc(rollNumber).get();

      if (existingStudent.exists) {
        throw 'A student with this roll number already exists';
      }

      // Create student record
      await _firestore.collection('students').doc(rollNumber).set({
        'rollNumber': rollNumber,
        'name': name,
        'class': className,
        'section': section,
        'parentEmail': parentEmail,
        'classTeacherId': classTeacherId,
        'studentFCMToken': studentFCMToken,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: 'Student registered successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      rethrow;
    }
  }

  // Register Teacher
  Future<void> registerTeacher({
    required String employeeId,
    required String name,
    required String department,
  }) async {
    try {
      // Check if teacher already exists
      final existingTeacher =
          await _firestore.collection('teachers').doc(employeeId).get();

      if (existingTeacher.exists) {
        throw 'A teacher with this employee ID already exists';
      }

      // Create teacher record
      await _firestore.collection('teachers').doc(employeeId).set({
        'employeeId': employeeId,
        'name': name,
        'department': department,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: 'Teacher registered successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      rethrow;
    }
  }

  // Register Parent
  Future<void> registerParent({
    required String name,
    required String phone,
    required String childRollNumber,
    required String parentFCMToken,
  }) async {
    try {
      // Verify student exists
      final studentDoc =
          await _firestore.collection('students').doc(childRollNumber).get();

      if (!studentDoc.exists) {
        throw 'No student found with roll number $childRollNumber';
      }

      // Check if parent already exists for this student
      final existingParent = await _firestore
          .collection('parents')
          .where('children', arrayContains: childRollNumber)
          .limit(1)
          .get();

      if (existingParent.docs.isNotEmpty) {
        throw 'A parent is already registered for student $childRollNumber';
      }

      final parentId = _uuid.v4();

      // Create parent record
      await _firestore.collection('parents').doc(parentId).set({
        'parentId': parentId,
        'name': name,
        'phone': phone,
        'children': [childRollNumber],
        'parentFCMToken': parentFCMToken,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update student with parent reference
      await _firestore.collection('students').doc(childRollNumber).update({
        'parentId': parentId,
      });

      Fluttertoast.showToast(msg: 'Parent registered successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      rethrow;
    }
  }
}
