// lib/services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitAttendance({
    required String classId,
    required String section,
    required DateTime date,
    required Map<String, bool> attendanceRecords,
    required String teacherId,
  }) async {
    try {
      // Create main attendance document
      final attendanceDocRef = _firestore.collection('attendance').doc();
      
      final attendanceData = {
        'class': classId,
        'section': section,
        'date': Timestamp.fromDate(date),
        'teacherId': teacherId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Batch write for atomic operation
      final batch = _firestore.batch();
      
      // Set main attendance document
      batch.set(attendanceDocRef, attendanceData);
      
      // Add student attendance records
      for (final entry in attendanceRecords.entries) {
        final studentDocRef = attendanceDocRef.collection('students').doc(entry.key);
        batch.set(studentDocRef, {
          'status': entry.value,
          'studentName': entry.key,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to submit attendance: $e');
    }
  }
}