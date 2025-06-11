import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userTypeKey = 'user_type';
  static const String _userIdKey = 'user_id';
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey) != null;
  }
  
  // Get current user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
  
  // Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  // Save user session
  static Future<void> _saveUserSession(String userType, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType);
    await prefs.setString(_userIdKey, userId);
  }
  
  // Clear user session (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userIdKey);
  }

  // Student Login
  Future<Map<String, dynamic>> loginStudent(String rollNumber) async {
    try {
      final doc = await _firestore.collection('students').doc(rollNumber).get();
      
      if (!doc.exists) {
        throw 'Student with roll number $rollNumber not found';
      }
      
      final userData = {
        'user': doc.data(),
        'role': 'student',
        'id': rollNumber,
      };
      await _saveUserSession('student', rollNumber);
      return userData;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      rethrow;
    }
  }

  // Teacher Login
  Future<Map<String, dynamic>> loginTeacher(String employeeId) async {
    try {
      final doc = await _firestore.collection('teachers').doc(employeeId).get();
      
      if (!doc.exists) {
        throw 'Teacher with employee ID $employeeId not found';
      }
      
      final userData = {
        'user': doc.data(),
        'role': 'teacher',
        'id': employeeId,
      };
      print('User Data: $userData');
      await _saveUserSession('teacher', employeeId);
      return userData;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      rethrow;
    }
  }

  // Parent Login
  Future<Map<String, dynamic>> loginParent(String rollNumber) async {
    try {
      // First find the student
      final studentDoc = await _firestore
          .collection('students')
          .doc(rollNumber)
          .get();
      
      if (!studentDoc.exists) {
        throw 'No student found with roll number $rollNumber';
      }
      
      // Find parent by child's roll number
      final parentQuery = await _firestore
          .collection('parents')
          .where('children', arrayContains: rollNumber)
          .limit(1)
          .get();
      
      if (parentQuery.docs.isEmpty) {
        throw 'No parent registered for student $rollNumber';
      }
      
      final parentData = parentQuery.docs.first.data();
      
      final userData = {
        'user': parentData,
        'student': studentDoc.data(),
        'role': 'parent',
        'id': parentQuery.docs.first.id,
      };
      await _saveUserSession('parent', parentQuery.docs.first.id);
      return userData;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      rethrow;
    }
  }
}
