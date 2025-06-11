import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? _userId;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      setState(() {
        _userId = userId;
      });
      _determineUserType();
    }
  }

  Future<void> _determineUserType() async {
    if (_userId == null) return;

    // Check if user is a student
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(_userId)
        .get();
    if (studentDoc.exists) {
      setState(() {
        _userType = 'student';
      });
      return;
    }

    // Check if user is a parent
    final parentQuery = await FirebaseFirestore.instance
        .collection('parents')
        .where('parentId', isEqualTo: _userId)
        .get();
    if (parentQuery.docs.isNotEmpty) {
      setState(() {
        _userType = 'parent';
      });
      return;
    }

    // Check if user is a teacher
    final teacherDoc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(_userId)
        .get();
    if (teacherDoc.exists) {
      setState(() {
        _userType = 'teacher';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('status', isEqualTo: 'sent')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyNotifications();
                }

                final messages = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final students = List<String>.from(data['students'] ?? []);
                  final recipientType = data['recipientType'] as String?;

                  if (_userType == 'student') {
                    return students.contains(_userId);
                  } else if (_userType == 'parent') {
                    return recipientType == 'Only Parents' || recipientType == 'Both';
                  } else if (_userType == 'teacher') {
                    return true; // Teachers can see all messages
                  }
                  return false;
                }).toList();

                if (messages.isEmpty) {
                  return _buildEmptyNotifications();
                }

                return ListView.builder(
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final timeAgo = timestamp != null
                        ? _getTimeAgo(timestamp.toDate())
                        : 'Unknown time';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            _getNotificationIcon(message['recipientType']),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          message['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(message['body'] ?? 'No Message'),
                            const SizedBox(height: 4),
                            Text(
                              'Class: ${message['class'] ?? 'N/A'} - Section: ${message['section'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No new notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String? recipientType) {
    switch (recipientType) {
      case 'Only Students':
        return Icons.school;
      case 'Only Parents':
        return Icons.family_restroom;
      case 'Both':
        return Icons.groups;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
