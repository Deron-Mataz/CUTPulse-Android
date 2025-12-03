import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationWidget extends StatelessWidget {
  final QueryDocumentSnapshot notif;

  const NotificationWidget({super.key, required this.notif});

  String _generateMessage(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final fromUsername = data['fromUsername'] ?? 'Someone';

    if (data['message'] != null && data['message'].toString().isNotEmpty) {
      return '${data['message']}';
    }

    switch (type) {
      case 'like':
        return '$fromUsername liked your post';
      case 'comment':
        return '$fromUsername commented on your post';
      case 'reply':
        return '$fromUsername replied to your comment';
      case 'follow':
        return '$fromUsername started following you';
      case 'warning':
        return 'Admin: ${data['text'] ?? 'You have received a warning'}';
      default:
        return '$fromUsername sent you a notification';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.thumb_up_alt_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'reply':
        return Icons.reply_rounded;
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'like':
        return Colors.blueAccent;
      case 'comment':
        return Colors.green;
      case 'reply':
        return Colors.purple;
      case 'follow':
        return Colors.orange;
      case 'warning':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  //amdin notifications (to add after )

  @override
  Widget build(BuildContext context) {
    final data = notif.data() as Map<String, dynamic>;
    final type = data['type'] ?? 'unknown';
    final fromUserId = data['fromUserId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final username = userData['username'] ?? 'Someone';
        final profilePhoto = userData['profilePhoto'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profilePhoto.isNotEmpty
                  ? NetworkImage(profilePhoto)
                  : null,
              backgroundColor: Colors.grey[300],
              child: profilePhoto.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              _generateMessage({...data, 'fromUsername': username}),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            subtitle: data['createdAt'] != null
                ? Text(
                    _formatTime(data['createdAt'] as Timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  )
                : null,
            trailing: Icon(_getIcon(type), color: _getIconColor(type)),
          ),
        );
      },
    );
  }
}
