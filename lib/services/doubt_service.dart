import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs for images

class DoubtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  // Get messages for a specific subject for a given user
  Stream<QuerySnapshot> getSubjectMessages(String userId, String subjectId) {
    // Ensure subjectId is clean and safe for document IDs (e.g., lowercase, no spaces/special chars)
    final cleanSubjectId = subjectId
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(cleanSubjectId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Order chronologically
        .snapshots();
  }

  // Define the addMessageToSubjectChat method here
  Future<void> addMessageToSubjectChat({
    required String userId,
    required String subjectId,
    required String message,
    String? imageUrl, // Optional for image messages
    required bool isUser, // true for user's message, false for AI's response
    // String? response, // This field is for the AI's response to a user's initial query,
    // not for every message. We'll handle it within the DoubtsPage logic.
  }) async {
    final cleanSubjectId = subjectId
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    final messageData = {
      'message': message,
      'isUser': isUser,
      'timestamp':
          FieldValue.serverTimestamp(), // Server timestamp for consistency
      if (imageUrl != null) 'imageUrl': imageUrl, // Only add if not null
      // 'response': response, // Removed from here, handled in DoubtsPage for the initial user query
    };

    // Add the message to the 'messages' subcollection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(cleanSubjectId)
        .collection('messages')
        .add(messageData);

    // Update the lastMessageTimestamp on the parent subject document
    // This also ensures the subject document is created if it doesn't exist
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(cleanSubjectId)
        .set(
      {
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'name': subjectId, // Store the human-readable subject name
      },
      SetOptions(
          merge:
              true), // Use merge: true to avoid overwriting other subject details
    );
  }

  // Upload image to Firebase Storage and return URL
  Future<String> uploadImage(File imageFile) async {
    try {
      final String fileName =
          'doubts/${_uuid.v4()}_${imageFile.path.split('/').last}';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
      rethrow; // Re-throw the error to be caught by the calling function
    }
  }

  // Removed the explicit ensureSubjectExists as addMessageToSubjectChat handles it with merge: true
}