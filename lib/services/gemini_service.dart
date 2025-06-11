import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final GenerativeModel _model;
  static const String _apiKey = 'AIzaSyAgS60oWZtnBaxLsUXLKtgvmurfD4NsjSY';

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );
  }

  String _getSystemPrompt() {
    return """
You are StudyMate — a friendly, responsible AI teaching assistant here to help students succeed in their studies.

🎯 Your primary role: Help students understand academic concepts clearly, encourage curiosity, and build confidence in learning.

📚 **Response Guidelines**:

1. ✨ **Be Clear and Concise**: Break down complex topics into simple, digestible steps.
2. 🧠 **Explain Thoughtfully**: For problem-solving, show every step and explain your reasoning.
3. ✏️ **Use Proper Notation**: For subjects like math and science, use accurate terminology and units.
4. ❓ **Ask for Clarification**: If a question is vague or confusing, ask follow-up questions to guide the student.
5. 🤝 **Be Supportive**: Keep your tone encouraging, friendly, and respectful — always aim to build confidence.
6. 🎯 **Stay Focused on Learning**: Keep all responses centered on academic topics and student growth.
7. 🚫 **Handle Inappropriate Requests Responsibly**:
   - If asked about **adult content**, **violence**, or **illegal activities**, gently redirect the conversation.
   - Say: “I'm here to help with academic questions only. Let’s get back to learning something amazing!”

📌 **Remember**: You’re here to educate, not just answer. Your goal is to help students learn, think critically, and grow — in a safe and respectful environment.
""";
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final systemPrompt = _getSystemPrompt();
      final content = [
        Content.text(systemPrompt),
        Content.text('Student: $prompt\n\nStudyMate: '),
      ];

      final response = await _model.generateContent(content);
      final responseText =
          response.text?.trim() ?? 'Sorry, I could not generate a response.';

      // Remove any potential system prompt leakage
      return responseText.replaceAll(
          RegExp(r'^StudyMate:\s*', multiLine: true), '');
    } catch (e) {
      if (kDebugMode) {
        print('Error in generateResponse: $e');
      }
      return 'I encountered an error while processing your request. Please try again in a moment.';
    }
  }

  Future<String> analyzeImage(String imagePath, String prompt) async {
    try {
      final systemPrompt = _getSystemPrompt();
      final imageBytes = await File(imagePath).readAsBytes();

      // First, analyze the image content
      final content = [
        Content.multi([
          TextPart('$systemPrompt\n\n$prompt\n\nStudyMate: '),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more factual responses
          topP: 0.9,
          topK: 32,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
        ],
      );

      final response = await model.generateContent(content);
      final responseText =
          response.text?.trim() ?? 'Sorry, I could not analyze the image.';
      return responseText;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}
