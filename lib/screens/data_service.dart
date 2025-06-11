import 'dart:async';
import 'package:flutter/material.dart';
import 'data_models.dart';

class DataService {
  Future<UserData> fetchUserData() async {
    await Future.delayed(const Duration(seconds: 2)); // simulate network delay

    return UserData(
      user: User(
        name: 'Eswar',
        xp: 2300,
        badges: 8,
        rank: 1,
        avatarUrl: 'https://via.placeholder.com/150',
      ),
      learners: List.generate(
        5,
        (i) => Learner(
          name: 'Learner ${i + 1}',
          avatarUrl: 'https://via.placeholder.com/150',
          rank: i + 1,
        ),
      ),
      reports: [
        SubjectReport(
            name: 'AI',
            percent: 85.6,
            icon: Icons.computer,
            color: Colors.green),
        SubjectReport(
            name: 'DSA', percent: 72.3, icon: Icons.code, color: Colors.orange),
      ],
      achievements: [
        Achievement(title: 'Quiz - 1', color: Colors.blue),
        Achievement(title: 'DSA Master', color: Colors.purple),
      ],
      progressList: [
        SubjectProgress(
            name: 'DSA', completed: 5, total: 6, color: Colors.blue),
        SubjectProgress(
            name: 'AI', completed: 4, total: 7, color: Colors.green),
      ],
      qaStats: QAStats(questions: 12, answers: 30, likes: 85),
      overviewItems: [
        OverviewItem(icon: Icons.task_alt, title: 'Tests Taken', count: 10),
        OverviewItem(icon: Icons.help, title: 'Doubts', count: 5),
        OverviewItem(icon: Icons.question_answer, title: 'Answers', count: 30),
        OverviewItem(icon: Icons.emoji_events, title: 'Badges', count: 8),
      ],
    );
  }
}
