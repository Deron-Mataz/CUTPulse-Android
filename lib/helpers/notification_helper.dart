import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static Future<void> createNotification({
    required String type,
    required String fromUserId,
    required String fromUsername,
    required String fromUserProfile,
    required String toUserId,
    String? postId,
    String? replyId,
    bool priority = false,
  }) async {
    if (fromUserId == toUserId) return;

    final notifRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc();

    await notifRef.set({
      'notificationId': notifRef.id,
      'type': type,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserProfile': fromUserProfile,
      'toUserId': toUserId,
      'postId': postId ?? '',
      'replyId': replyId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'priority': priority,
    });
  }
}
