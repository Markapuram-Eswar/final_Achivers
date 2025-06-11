import 'package:cloud_firestore/cloud_firestore.dart';

class TextBookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch textbook content for a given school, grade, subject, and topic
  Future<Map<String, dynamic>?> getTextbookContent({
    required String school,
    required String grade,
    required String subject,
    required String topic,
  }) async {
    try {
      // Reference to the textbooks collection and the specific school document
      DocumentSnapshot schoolDoc =
          await _firestore.collection('textbooks').doc(school).get();

      if (!schoolDoc.exists) {
        print('School document not found.');
        return null;
      }

      final data = schoolDoc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Traverse to the grade map
      final gradeMap = data[grade] as Map<String, dynamic>?;
      if (gradeMap == null) return null;

      // Traverse to the subject map
      final subjectMap = gradeMap[subject] as Map<String, dynamic>?;
      if (subjectMap == null) return null;

      // Get the topic content
      final topicContent = subjectMap[topic];
      if (topicContent == null) return null;

      // Process the content to ensure it has the required audio fields
      Map<String, dynamic> processedContent;
      if (topicContent is List) {
        // If it's a list, wrap it in a content map
        processedContent = {'content': topicContent};
      } else if (topicContent is Map<String, dynamic>) {
        processedContent = topicContent;
      } else {
        processedContent = {'content': [topicContent]};
      }

      // Ensure each content item has audio URLs
      if (processedContent['content'] is List) {
        final contentList = processedContent['content'] as List;
        for (var i = 0; i < contentList.length; i++) {
          if (contentList[i] is Map<String, dynamic>) {
            final item = contentList[i] as Map<String, dynamic>;
            // Add audio URLs if they don't exist
            if (!item.containsKey('audio_kidmale')) {
              item['audio_kidmale'] = null;
            }
            if (!item.containsKey('audio_kidfemale')) {
              item['audio_kidfemale'] = null;
            }
            if (!item.containsKey('audio_male')) {
              item['audio_male'] = null;
            }
            if (!item.containsKey('audio_female')) {
              item['audio_female'] = null;
            }
          }
        }
      }

      return processedContent;
    } catch (e) {
      print('Error fetching textbook content: $e');
      return null;
    }
  }
}
