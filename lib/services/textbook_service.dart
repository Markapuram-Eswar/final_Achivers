import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TextbookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all subjects for a class
  Future<Map<String, dynamic>> getClassSubjects(String classNumber) async {
    try {
      // First try to get the first document in the textbooks collection
      final querySnapshot = await _firestore.collection('textbooks').limit(1).get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No documents found in textbooks collection');
      }

      final doc = querySnapshot.docs.first;
      debugPrint('Found document with ID: ${doc.id}'); // Debug print

      final data = doc.data();
      if (data == null) {
        throw Exception('No data found in textbook document');
      }

      final classData = data[classNumber] as Map<String, dynamic>?;
      if (classData == null) {
        throw Exception('Class $classNumber not found');
      }

      // Get the Language Learning section which contains other subjects
      final languageLearning =
          classData['Language Learning'] as Map<String, dynamic>?;
      if (languageLearning == null) {
        throw Exception(
            'Language Learning section not found in class $classNumber');
      }

      // Return the subjects under Language Learning
      return languageLearning;
    } catch (e) {
      debugPrint('Error getting class subjects: $e');
      rethrow;
    }
  }

  // Stream all subjects for a class
  Stream<Map<String, dynamic>> streamClassSubjects(String classNumber) {
    return _firestore
        .collection('textbooks')
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No documents found in textbooks collection');
      }

      final doc = querySnapshot.docs.first;
      debugPrint('Found document with ID: ${doc.id}'); // Debug print

      final data = doc.data();
      if (data == null) {
        throw Exception('No data found in textbook document');
      }

      final classData = data[classNumber] as Map<String, dynamic>?;
      if (classData == null) {
        throw Exception('Class $classNumber not found');
      }

      // Get the Language Learning section which contains other subjects
      final languageLearning =
          classData['Language Learning'] as Map<String, dynamic>?;
      if (languageLearning == null) {
        throw Exception(
            'Language Learning section not found in class $classNumber');
      }

      // Return the subjects under Language Learning
      return languageLearning;
    });
  }

  // Get content for a specific topic
  Future<List<Map<String, dynamic>>> getTextbookContent({
    required String classNumber,
    required String subject,
    required String topic,
  }) async {
    try {
      // First try to get the first document in the textbooks collection
      final querySnapshot = await _firestore.collection('textbooks').limit(1).get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No documents found in textbooks collection');
      }

      final doc = querySnapshot.docs.first;
      debugPrint('Found document with ID: ${doc.id}'); // Debug print

      final data = doc.data();
      if (data == null) {
        throw Exception('No data found in textbook document');
      }

      final classData = data[classNumber] as Map<String, dynamic>?;
      if (classData == null) {
        throw Exception('Class $classNumber not found');
      }

      // Get the Language Learning section
      final languageLearning =
          classData['Language Learning'] as Map<String, dynamic>?;
      if (languageLearning == null) {
        throw Exception(
            'Language Learning section not found in class $classNumber');
      }

      // Get the subject under Language Learning
      final subjectData = languageLearning[subject] as Map<String, dynamic>?;
      if (subjectData == null) {
        final availableSubjects = languageLearning.keys.join(', ');
        throw Exception(
          'Subject "$subject" not found in class $classNumber. Available subjects: $availableSubjects',
        );
      }

      // Get the topic
      final topicData = subjectData[topic] as List<dynamic>?;
      if (topicData == null) {
        final availableTopics = subjectData.keys.join(', ');
        throw Exception(
          'Topic "$topic" not found in subject "$subject". Available topics: $availableTopics',
        );
      }

      // Process the content
      return topicData.map((item) {
        final Map<String, dynamic> content =
            Map<String, dynamic>.from(item as Map);
        // Ensure all audio fields exist with empty string as default
        content['audio_female'] ??= '';
        content['audio_kidfemale'] ??= '';
        content['audio_kidmale'] ??= '';
        content['audio_male'] ??= '';
        return content;
      }).toList();
    } catch (e) {
      debugPrint('Error getting textbook content: $e');
      rethrow;
    }
  }

  // Stream content for a specific topic
  Stream<List<Map<String, dynamic>>> streamTextbookContent({
    required String classNumber,
    required String subject,
    required String topic,
  }) {
    return _firestore
        .collection('textbooks')
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No documents found in textbooks collection');
      }

      final doc = querySnapshot.docs.first;
      debugPrint('Found document with ID: ${doc.id}'); // Debug print

      final data = doc.data();
      if (data == null) {
        throw Exception('No data found in textbook document');
      }

      final classData = data[classNumber] as Map<String, dynamic>?;
      if (classData == null) {
        throw Exception('Class $classNumber not found');
      }

      // Get the Language Learning section
      final languageLearning =
          classData['Language Learning'] as Map<String, dynamic>?;
      if (languageLearning == null) {
        throw Exception(
            'Language Learning section not found in class $classNumber');
      }

      // Get the subject under Language Learning
      final subjectData = languageLearning[subject] as Map<String, dynamic>?;
      if (subjectData == null) {
        final availableSubjects = languageLearning.keys.join(', ');
        throw Exception(
          'Subject "$subject" not found in class $classNumber. Available subjects: $availableSubjects',
        );
      }

      // Get the topic
      final topicData = subjectData[topic] as List<dynamic>?;
      if (topicData == null) {
        final availableTopics = subjectData.keys.join(', ');
        throw Exception(
          'Topic "$topic" not found in subject "$subject". Available topics: $availableTopics',
        );
      }

      // Process the content
      return topicData.map((item) {
        final Map<String, dynamic> content =
            Map<String, dynamic>.from(item as Map);
        // Ensure all audio fields exist with empty string as default
        content['audio_female'] ??= '';
        content['audio_kidfemale'] ??= '';
        content['audio_kidmale'] ??= '';
        content['audio_male'] ??= '';
        return content;
      }).toList();
    });
  }
}
