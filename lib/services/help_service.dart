import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class HelpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitHelpRequest({
    required String name,
    required String email,
    required String issue,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('Submitting help request for user: $userId');
      print('User type: $userType');
      print('Name: $name');
      print('Email: $email');
      print('Issue: $issue');

      // Create help request document
      final helpRequest = {
        'userId': userId,
        'userType': userType,
        'name': name,
        'email': email,
        'issue': issue,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Submitting help request: $helpRequest');

      final docRef = await _firestore.collection('help_requests').add(helpRequest);
      print('Help request submitted successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error in submitHelpRequest: $e');
      throw Exception('Failed to submit help request: $e');
    }
  }

  Stream<QuerySnapshot> getHelpRequests() async* {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      yield* _firestore
          .collection('help_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Error in getHelpRequests: $e');
      throw Exception('Failed to get help requests: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllHelpRequests() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('help_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toString() ?? 'N/A',
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toString() ?? 'N/A',
        };
      }).toList();
    } catch (e) {
      print('Error fetching help requests: $e');
      throw Exception('Failed to fetch help requests: $e');
    }
  }

  Future<void> printHelpRequests() async {
    try {
      final requests = await getAllHelpRequests();
      print('\n=== Help Requests in Firestore ===');
      for (var request in requests) {
        print('\nRequest ID: ${request['id']}');
        print('User ID: ${request['userId']}');
        print('User Type: ${request['userType']}');
        print('Name: ${request['name']}');
        print('Email: ${request['email']}');
        print('Issue: ${request['issue']}');
        print('Status: ${request['status']}');
        print('Created At: ${request['createdAt']}');
        print('Updated At: ${request['updatedAt']}');
        print('----------------------------------------');
      }
      print('\nTotal Requests: ${requests.length}');
    } catch (e) {
      print('Error printing help requests: $e');
    }
  }
}
