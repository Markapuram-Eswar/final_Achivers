import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'ProfileService.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> applyLeaveForChild({
    required String childRollNumber,
    required String leaveType,
    required String reason,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null || userType != 'parent') {
        throw 'Unauthorized: Only parents can apply leave for children.';
      }

      // Get parent details
      final parentDoc = await _firestore.collection('parents').doc(userId).get();
      if (!parentDoc.exists) {
        throw 'Parent profile not found';
      }

      // Get student profile
      final studentProfile = await ProfileService().getStudentProfileById(childRollNumber);
      if (studentProfile == null) {
        throw 'Student with roll number $childRollNumber not found';
      }

      // Get class teacher or use default admin
      String classTeacher;
      if (studentProfile['classTeacher'] == null || studentProfile['classTeacher'].toString().trim().isEmpty) {
        print('Warning: No class teacher assigned for student $childRollNumber');
        // Use default admin ID for leave applications without a class teacher
        classTeacher = 'admin123'; // Replace with your actual admin ID
        print('Using admin ID: $classTeacher for leave application');
      } else {
        classTeacher = studentProfile['classTeacher'].toString().trim();
      }

      // Create leave application
      final leaveData = {
        'childId': studentProfile['userId'],
        'childRollNumber': childRollNumber,
        'class': studentProfile['class'],
        'section': studentProfile['section'],
        'classTeacher': classTeacher,
        'leaveType': leaveType,
        'reason': reason,
        'fromDate': Timestamp.fromDate(fromDate),
        'toDate': Timestamp.fromDate(toDate),
        'appliedBy': userId,
        'appliedAt': Timestamp.now(),
        'status': 'pending',
        'parentName': parentDoc.data()?['name'] ?? 'Unknown',
        'parentPhone': parentDoc.data()?['phone'] ?? 'Unknown',
        'needsAdminReview': classTeacher == 'admin123', // Flag for admin review
      };

      // Add to leave_applications collection
      final leaveDoc = await _firestore.collection('leave_applications').add(leaveData);
      
      // Add to teacher's leave_appointments field
      await _firestore.collection('teachers').doc(classTeacher).update({
        'leave_appointments': FieldValue.arrayUnion([leaveDoc.id])
      });

      print('Leave application submitted successfully: ${leaveDoc.id}');
    } catch (e) {
      print('Error applying leave: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeavesForClassTeacher(String teacherId) async {
    try {
      // Get teacher's leave_appointments array
      final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
      if (!teacherDoc.exists) {
        throw 'Teacher not found';
      }

      final leaveAppointments = List<String>.from(teacherDoc.data()?['leave_appointments'] ?? []);
      if (leaveAppointments.isEmpty) {
        return [];
      }

      // Get all leave applications
      final leaveDocs = await _firestore
          .collection('leave_applications')
          .where(FieldPath.documentId, whereIn: leaveAppointments)
          .orderBy('appliedAt', descending: true)
          .get();

      return leaveDocs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting leaves for class teacher: $e');
      rethrow;
    }
  }

  Future<void> updateLeaveStatus(String leaveId, String status) async {
    try {
      final leaveDoc = await _firestore.collection('leave_applications').doc(leaveId).get();
      if (!leaveDoc.exists) {
        throw 'Leave application not found';
      }

      final leaveData = leaveDoc.data()!;
      final classTeacher = leaveData['classTeacher'];

      // Update leave status
      await _firestore.collection('leave_applications').doc(leaveId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // If rejected, remove from teacher's leave_appointments
      if (status == 'rejected') {
        await _firestore.collection('teachers').doc(classTeacher).update({
          'leave_appointments': FieldValue.arrayRemove([leaveId])
        });
      }
    } catch (e) {
      print('Error updating leave status: $e');
      rethrow;
    }
  }
}
