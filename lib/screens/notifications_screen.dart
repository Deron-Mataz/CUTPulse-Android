import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/notification_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

//must add widget!! after completion!!
class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  List<QueryDocumentSnapshot> priorityNotifications = [];
  List<QueryDocumentSnapshot> recentNotifications = [];
  List<QueryDocumentSnapshot> olderNotifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  Future<void> _markNotificationsAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins()),
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('toUserId', isEqualTo: currentUser.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              unreadCount = snapshot.data!.docs.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;
          priorityNotifications = [];
          recentNotifications = [];
          olderNotifications = [];

          for (var notif in notifications) {
            final createdAt = notif['createdAt'] as Timestamp?;
            if (createdAt == null) continue;

            final diff = DateTime.now().difference(createdAt.toDate()).inDays;
            if (notif['priority'] == true && priorityNotifications.length < 3) {
              priorityNotifications.add(notif);
            } else if (diff <= 7) {
              recentNotifications.add(notif);
            } else {
              olderNotifications.add(notif);
            }
          }

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No notifications yet.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (priorityNotifications.isNotEmpty) ...[
                    Text(
                      'Priority',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...priorityNotifications.map(
                      (notif) => NotificationWidget(notif: notif),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (recentNotifications.isNotEmpty) ...[
                    Text(
                      'Recent',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recentNotifications.map(
                      (notif) => NotificationWidget(notif: notif),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (olderNotifications.isNotEmpty) ...[
                    Text(
                      'Older',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...olderNotifications.map(
                      (notif) => NotificationWidget(notif: notif),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
