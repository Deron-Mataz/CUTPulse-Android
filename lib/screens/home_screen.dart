import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/post_widget.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 60,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and title
            Row(
              children: [
                CustomPaint(size: const Size(32, 32), painter: LogoPainter()),
                const SizedBox(width: 8),
                const Text(
                  "CUTPulse",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('toUserId', isEqualTo: currentUser.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData) {
                  unreadCount = snapshot.data!.docs.length;
                }

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.blue),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );

                        setState(() {});
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No posts yet. Be the first to post!"),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              return PostWidget(postData: postData);
            },
          );
        },
      ),
    );
  }
}
//paste logo...bootleg and edit accord to notes

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, Colors.lightBlueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final circle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2,
        ),
      );
    canvas.drawPath(circle, paint);

    final pulsePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final leftX = size.width * 0.15;
    final rightX = size.width * 0.85;
    final totalWidth = rightX - leftX;

    final spikeHeight = size.height * 0.25;
    final dipHeight = size.height * 0.12;

    final pulsePath = Path();
    pulsePath.moveTo(leftX, centerY);

    pulsePath.lineTo(leftX + totalWidth * 0.2, centerY);

    pulsePath.lineTo(leftX + totalWidth * 0.3, centerY - spikeHeight);

    pulsePath.lineTo(leftX + totalWidth * 0.4, centerY + dipHeight);

    pulsePath.lineTo(leftX + totalWidth * 0.6, centerY);

    pulsePath.lineTo(leftX + totalWidth * 0.7, centerY - spikeHeight * 0.4);
    pulsePath.lineTo(leftX + totalWidth * 0.8, centerY);

    pulsePath.lineTo(rightX, centerY);

    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
