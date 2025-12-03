import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/post_widget.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final postsQuery = FirebaseFirestore.instance
        .collection('posts')
        .where('likers', arrayContains: currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My Likes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: postsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final postDocs = snapshot.data?.docs ?? [];

          if (postDocs.isEmpty) {
            return const Center(child: Text('No liked posts yet.'));
          }

          return ListView.builder(
            itemCount: postDocs.length,
            itemBuilder: (context, index) {
              final postData = postDocs[index].data() as Map<String, dynamic>;
              postData['postId'] = postDocs[index].id;
              return PostWidget(postData: postData);
            },
          );
        },
      ),
    );
  }
}
