import 'package:flutter/material.dart';

class User {
  final String name;
  final int xp, badges, rank;
  final String avatarUrl;

  User(
      {required this.name,
      required this.xp,
      required this.badges,
      required this.rank,
      required this.avatarUrl});
}

class Learner {
  final String name, avatarUrl;
  final int rank;

  Learner({required this.name, required this.avatarUrl, required this.rank});
}

class SubjectReport {
  final String name;
  final double percent;
  final IconData icon;
  final Color color;

  SubjectReport(
      {required this.name,
      required this.percent,
      required this.icon,
      required this.color});
}

class Achievement {
  final String title;
  final Color color;

  Achievement({required this.title, required this.color});
}

class SubjectProgress {
  final String name;
  final int completed, total;
  final Color color;

  SubjectProgress(
      {required this.name,
      required this.completed,
      required this.total,
      required this.color});
}

class QAStats {
  final int questions, answers, likes;

  QAStats(
      {required this.questions, required this.answers, required this.likes});
}

class OverviewItem {
  final IconData icon;
  final String title;
  final int count;

  OverviewItem({required this.icon, required this.title, required this.count});
}

class UserData {
  final User user;
  final List<Learner> learners;
  final List<SubjectReport> reports;
  final List<Achievement> achievements;
  final List<SubjectProgress> progressList;
  final QAStats qaStats;
  final List<OverviewItem> overviewItems;

  UserData({
    required this.user,
    required this.learners,
    required this.reports,
    required this.achievements,
    required this.progressList,
    required this.qaStats,
    required this.overviewItems,
  });
}
