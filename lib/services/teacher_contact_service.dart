import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection structure:
  // teachers (collection)
  //   - teacherId (document)
  //     - name: string
  //     - subject: string
  //     - phone: string
  //     - email: string
  //     - classes: array of strings (e.g., ["6-A", "7-B"])
  //     - image: string (first letter of name)
  //     - isActive: boolean
  //     - createdAt: timestamp
  //     - updatedAt: timestamp

  Future<List<Map<String, dynamic>>> getTeachersByClass(
      String className) async {
    try {
      final QuerySnapshot teachersSnapshot = await _firestore
          .collection('teachers')
          .where('classes', arrayContains: className)
          .get();

      return teachersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'subject': data['subject'] ?? '',
          'phone': data['phone'] ?? '',
          'email': data['email'] ?? '',
          'image': data['image'] ?? data['name']?[0] ?? 'T',
          'classes': List<String>.from(data['classes'] ?? []),
        };
      }).toList();
    } catch (e) {
      print('Error fetching teachers by class: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllActiveTeachers() async {
    try {
      final QuerySnapshot teachersSnapshot = await _firestore
          .collection('teachers')
          .where('isActive', isEqualTo: true)
          .get();

      return teachersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'subject': data['subject'] ?? '',
          'phone': data['phone'] ?? '',
          'email': data['email'] ?? '',
          'image': data['image'] ?? data['name']?[0] ?? 'T',
          'classes': List<String>.from(data['classes'] ?? []),
        };
      }).toList();
    } catch (e) {
      print('Error fetching all teachers: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTeacherById(String teacherId) async {
    try {
      final DocumentSnapshot teacherDoc =
          await _firestore.collection('teachers').doc(teacherId).get();

      if (!teacherDoc.exists) {
        return null;
      }

      final data = teacherDoc.data() as Map<String, dynamic>;
      return {
        'id': teacherDoc.id,
        'name': data['name'] ?? '',
        'subject': data['subject'] ?? '',
        'phone': data['phone'] ?? '',
        'email': data['email'] ?? '',
        'image': data['image'] ?? data['name']?[0] ?? 'T',
        'classes': List<String>.from(data['classes'] ?? []),
      };
    } catch (e) {
      print('Error fetching teacher by ID: $e');
      rethrow;
    }
  }
}
