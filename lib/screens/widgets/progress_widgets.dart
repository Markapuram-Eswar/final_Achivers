import 'package:flutter/material.dart';
import 'package:achiver_app/screens/data_models.dart';

// -------------------- USER SUMMARY --------------------
class UserSummary extends StatelessWidget {
  final User user;
  const UserSummary({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    'XP: ${user.xp} | Rank: ${user.rank} | Badges: ${user.badges}')
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- TOP LEARNERS --------------------
class TopLearners extends StatelessWidget {
  final List<Learner> learners;
  const TopLearners({super.key, required this.learners});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text("Top Learners",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: learners.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final learner = learners[index];
              return Column(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(learner.avatarUrl),
                    radius: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(learner.name, style: const TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------- PROGRESS REPORT --------------------
class ProgressReport extends StatelessWidget {
  final List<SubjectReport> reports;
  const ProgressReport({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Progress Report",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...reports.map((r) => Column(
                  children: [
                    ListTile(
                      leading: Icon(r.icon, color: r.color),
                      title: Text(r.name),
                      subtitle:
                          Text('${r.percent.toStringAsFixed(1)}% complete'),
                    ),
                    const Divider()
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

// -------------------- RECENT ACHIEVEMENTS --------------------
class RecentAchievements extends StatelessWidget {
  final List<Achievement> achievements;
  const RecentAchievements({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Achievements",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: achievements
                  .map((a) => Chip(
                        label: Text(a.title),
                        backgroundColor: a.color.withValues(alpha: 0.2),
                        labelStyle: TextStyle(color: a.color),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- LEARNING PROGRESS --------------------
class LearningProgress extends StatelessWidget {
  final List<SubjectProgress> progressList;
  const LearningProgress({super.key, required this.progressList});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Learning Progress",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...progressList.map((p) {
              final percent = p.completed / p.total;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.name} (${p.completed}/${p.total})'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent,
                    color: p.color,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}

// -------------------- QA SUMMARY --------------------
class QASummary extends StatelessWidget {
  final QAStats stats;
  const QASummary({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Questions & Answers",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  const Icon(Icons.question_answer),
                  Text('${stats.questions} Questions')
                ]),
                Column(children: [
                  const Icon(Icons.reply),
                  Text('${stats.answers} Answers')
                ]),
                Column(children: [
                  const Icon(Icons.thumb_up),
                  Text('${stats.likes} Likes')
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ACHIEVEMENT OVERVIEW --------------------
class AchievementOverview extends StatelessWidget {
  final List<OverviewItem> items;
  const AchievementOverview({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Achievement Overview",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: items
                  .map((item) => Chip(
                        avatar: Icon(item.icon),
                        label: Text('${item.title}: ${item.count}'),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
