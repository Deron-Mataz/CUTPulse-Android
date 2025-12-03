import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  String username = 'Loading...';
  String profilePhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (doc.exists) {
      setState(() {
        username = doc.data()?['username'] ?? 'Unknown';
        profilePhotoUrl = doc.data()?['profilePhoto'] ?? '';
      });
    }
  }

  Future<void> _sendCommentNotification(
    String commentText,
    String commentId,
  ) async {
    try {
      // Fetch post owner
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
      if (!postDoc.exists) return;
      final postOwnerId = postDoc.data()?['userId'];
      if (postOwnerId == null || postOwnerId == currentUser.uid) {
        return; // Don't notify self
      }

      // Add notification to post owner
      await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('notifications')
          .add({
            'type': 'comment',
            'fromUserId': currentUser.uid,
            'postId': widget.postId,
            'commentId': commentId,
            'text': commentText,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      debugPrint('Error sending comment notification: $e');
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final commentRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'commentId': commentRef.id,
        'userId': currentUser.uid,
        'username': username,
        'profilePhoto': profilePhotoUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'repliesCount': 0,
      });

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'commentsCount': FieldValue.increment(1)});

      _commentController.clear();

      _sendCommentNotification(text, commentRef.id);
    } catch (e) {
      debugPrint("Error adding comment: $e");
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'commentsCount': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint("Error deleting comment: $e");
    }
  }

  Future<void> _editComment(String commentId, String oldText) async {
    _commentController.text = oldText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _commentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Edit your comment",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final newText = _commentController.text.trim();
                if (newText.isEmpty) return;
                try {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .update({'text': newText});

                  Navigator.pop(context);
                  _commentController.clear();
                } catch (e) {
                  debugPrint("Error editing comment: $e");
                }
              },
              child: const Text("Update Comment"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReply(String commentId, String replyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .delete();

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({'repliesCount': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint("Error deleting reply: $e");
    }
  }

  // ignore: unused_element
  Widget _commentMenu(Map<String, dynamic> comment) {
    final isOwner = comment['userId'] == currentUser.uid;
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _editComment(comment['commentId'], comment['text']);
        }
        if (value == 'delete') _deleteComment(comment['commentId']);
        if (value == 'report') {
          debugPrint("Reported comment ${comment['commentId']}");
        }
      },
      itemBuilder: (_) {
        if (isOwner) {
          return [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ];
        } else {
          return [const PopupMenuItem(value: 'report', child: Text('Report'))];
        }
      },
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final isOwner = comment['userId'] == currentUser.uid;
    final profilePhoto = comment['profilePhoto'] ?? '';
    final text = comment['text'] ?? '';
    final username = comment['username'] ?? 'Unknown';

    return _CommentTileWithReplies(
      comment: comment,
      profilePhoto: profilePhoto,
      username: username,
      text: text,
      isOwner: isOwner,
      postId: widget.postId,
      deleteComment: _deleteComment,
      editComment: _editComment,
      deleteReply: _deleteReply,
      currentUser: currentUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments', style: GoogleFonts.poppins())),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentTile(comment);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTileWithReplies extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String profilePhoto;
  final String username;
  final String text;
  final bool isOwner;
  final String postId;
  final Function(String) deleteComment;
  final Function(String, String) editComment;
  final Function(String, String) deleteReply;
  final User currentUser;

  const _CommentTileWithReplies({
    required this.comment,
    required this.profilePhoto,
    required this.username,
    required this.text,
    required this.isOwner,
    required this.postId,
    required this.deleteComment,
    required this.editComment,
    required this.deleteReply,
    required this.currentUser,
  });

  @override
  State<_CommentTileWithReplies> createState() =>
      _CommentTileWithRepliesState();
}

class _CommentTileWithRepliesState extends State<_CommentTileWithReplies> {
  bool showReplies = false;
  int repliesToShow = 4;

  @override
  Widget build(BuildContext context) {
    final commentId = widget.comment['commentId'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.profilePhoto.isNotEmpty
                    ? NetworkImage(widget.profilePhoto)
                    : null,
                child: widget.profilePhoto.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(widget.text, style: GoogleFonts.poppins(fontSize: 13)),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.editComment(commentId, widget.text);
                  }
                  if (value == 'delete') widget.deleteComment(commentId);
                  if (value == 'report') {
                    debugPrint("Reported comment $commentId");
                  }
                },
                itemBuilder: (_) {
                  if (widget.isOwner) {
                    return [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  } else {
                    return [
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report'),
                      ),
                    ];
                  }
                },
              ),
            ],
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .doc(commentId)
              .collection('replies')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final repliesDocs = snapshot.data!.docs;
            if (repliesDocs.isEmpty) return const SizedBox();

            final replies = repliesDocs
                .map((e) => e.data() as Map<String, dynamic>)
                .toList();
            final displayCount = showReplies
                ? replies.length
                : repliesToShow.clamp(0, replies.length);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(displayCount, (i) {
                  final reply = replies[i];
                  final isOwnerReply =
                      reply['userId'] == widget.currentUser.uid;
                  return Container(
                    margin: const EdgeInsets.only(left: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: reply['profilePhoto'] != null
                              ? NetworkImage(reply['profilePhoto'])
                              : null,
                          child: reply['profilePhoto'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply['username'] ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reply['text'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              widget.deleteReply(commentId, reply['replyId']);
                            }
                            if (value == 'report') {
                              debugPrint("Reported reply ${reply['replyId']}");
                            }
                          },
                          itemBuilder: (_) {
                            if (isOwnerReply) {
                              return [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ];
                            } else {
                              return [
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('Report'),
                                ),
                              ];
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
                if (replies.length > displayCount)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showReplies = !showReplies;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 40,
                        top: 4,
                        bottom: 4,
                      ),
                      child: Text(
                        showReplies ? 'Show less' : 'See more replies',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
