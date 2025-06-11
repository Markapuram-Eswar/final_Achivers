import 'package:flutter/material.dart';

class ViewHomeworkScreen extends StatelessWidget {
  const ViewHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> homework = [
      {
        'subject': 'Mathematics',
        'title': 'Quadratic Equations',
        'dueDate': 'Tomorrow',
        'status': 'Pending',
        'description': 'Complete exercises 5.1 and 5.2 from NCERT textbook',
      },
      {
        'subject': 'Science',
        'title': 'Chemical Reactions',
        'dueDate': 'Next Week',
        'status': 'Completed',
        'description': 'Write a report on the experiment conducted in class',
      },
      {
        'subject': 'English',
        'title': 'Essay Writing',
        'dueDate': 'Friday',
        'status': 'Pending',
        'description': 'Write an essay on "Environmental Conservation"',
      },
      {
        'subject': 'Hindi',
        'title': 'कविता लेखन',
        'dueDate': 'Next Monday',
        'status': 'Pending',
        'description': 'Write a poem on the topic "मेरा देश"',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text(
          'Homework',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: homework.length,
        itemBuilder: (context, index) {
          final assignment = homework[index];
          final bool isCompleted = assignment['status'] == 'Completed';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor:
                    isCompleted ? Colors.green[100] : Colors.orange[100],
                child: Icon(
                  isCompleted ? Icons.check : Icons.pending,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
              title: Text(
                assignment['subject'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(assignment['title']),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${assignment['dueDate']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          assignment['status'],
                          style: TextStyle(
                            color:
                                isCompleted ? Colors.green : Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(assignment['description']),
                      const SizedBox(height: 16),
                      if (!isCompleted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked homework as completed'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text(
                              'Mark as Completed',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
