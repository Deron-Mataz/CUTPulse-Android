import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/comments_screen.dart';
import '../helpers/notification_helper.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostWidget({super.key, required this.postData});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isExpanded = false;
  static const int maxLinesCollapsed = 4;

  String username = 'Loading...';
  String profilePhoto = '';
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
    _fetchUserData();
    _fetchLikeAndCommentData();
  }

  Future<void> _checkIfBlocked() async {
    try {
      final postOwnerId = widget.postData['userId'];
      if (postOwnerId == null) return;

      final blockedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(postOwnerId)
          .get();

      if (mounted) setState(() => _isBlocked = blockedDoc.exists);
    } catch (e) {
      debugPrint("Error checking blocked user: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = widget.postData['userId'];
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          username = doc.data()?['username'] ?? 'Unknown';
          profilePhoto = doc.data()?['profilePhoto'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) setState(() => username = 'Unknown');
    }
  }

  Future<void> _fetchLikeAndCommentData() async {
    try {
      final postId = widget.postData['postId'];
      if (postId == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);

      postRef.snapshots().listen((postDoc) {
        if (!mounted || !postDoc.exists) return;
        final data = postDoc.data();
        setState(() {
          likeCount = data?['likesCount'] ?? 0;
          commentCount = data?['commentsCount'] ?? 0;
          final likers = List<String>.from(data?['likers'] ?? []);
          isLiked = likers.contains(currentUser.uid);
        });
      });
    } catch (e) {
      debugPrint("Error fetching like/comment data: $e");
    }
  }

  Future<void> _toggleLike() async {
    try {
      final postId = widget.postData['postId'];
      final postOwnerId = widget.postData['userId'];
      if (postId == null || postOwnerId == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);

      if (isLiked) {
        await postRef.update({
          'likers': FieldValue.arrayRemove([currentUser.uid]),
          'likesCount': FieldValue.increment(-1),
        });
        await postRef.collection('likes').doc(currentUser.uid).delete();
      } else {
        await postRef.update({
          'likers': FieldValue.arrayUnion([currentUser.uid]),
          'likesCount': FieldValue.increment(1),
        });
        await postRef.collection('likes').doc(currentUser.uid).set({
          'likedAt': FieldValue.serverTimestamp(),
        });
        await NotificationHelper.createNotification(
          type: 'like',
          fromUserId: currentUser.uid,
          fromUsername: currentUser.displayName ?? 'User',
          fromUserProfile: currentUser.photoURL ?? '',
          toUserId: postOwnerId,
          postId: postId,
          priority: true,
        );
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  void _openComments() {
    final postId = widget.postData['postId'];
    if (postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
      ).then((_) => _fetchLikeAndCommentData());
    }
  }

  void _openPostMenu() {
    final postId = widget.postData['postId'];
    final postOwnerId = widget.postData['userId'];
    final isOwner = currentUser.uid == postOwnerId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text("Edit Post"),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Edit post tapped")),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Delete Post"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (postId != null) {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .delete();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Post deleted")),
                        );
                      }
                    }
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text("Report Post"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportBottomSheet(postId, postOwnerId);
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showReportBottomSheet(String postId, String postOwnerId) {
    String selectedReason = '';
    final TextEditingController otherController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Report Post",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Select a reason for reporting this post:",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      "Spam",
                      "Inappropriate Content",
                      "Bullying / Harassment",
                      "Other",
                    ].map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() => selectedReason = value!);
                        },
                      );
                    }).toList(),
                    if (selectedReason == "Other")
                      TextField(
                        controller: otherController,
                        decoration: const InputDecoration(
                          labelText: "Please describe the issue",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () async {
                            final reason = selectedReason == "Other"
                                ? otherController.text.trim()
                                : selectedReason;

                            if (reason.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select a reason."),
                                ),
                              );
                              return;
                            }

                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            Navigator.pop(ctx);

                            try {
                              await FirebaseFirestore.instance
                                  .collection('reports')
                                  .add({
                                    'postId': postId,
                                    'userId': postOwnerId,
                                    'reportedBy': currentUser.uid,
                                    'reason': reason,
                                    'status': 'Pending',
                                    'dateReported':
                                        FieldValue.serverTimestamp(),
                                  });

                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Report submitted successfully.",
                                  ),
                                ),
                              );
                            } catch (e) {
                              debugPrint("Error submitting report: $e");
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Failed to submit report. Try again.",
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) return const SizedBox.shrink();

    final textContent = widget.postData['textContent'] as String?;
    final imageUrl = widget.postData['imageUrl'] as String?;
    final createdAt = widget.postData['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profilePhoto.isNotEmpty
                      ? NetworkImage(profilePhoto)
                      : null,
                  child: profilePhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                Text(
                  _formatTimeAgo(createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _openPostMenu,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (textContent != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final textSpan = TextSpan(
                    text: textContent,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  );

                  final textPainter = TextPainter(
                    text: textSpan,
                    maxLines: isExpanded ? null : maxLinesCollapsed,
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: constraints.maxWidth);

                  final isOverflow = textPainter.didExceedMaxLines;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textContent,
                        maxLines: isExpanded ? null : maxLinesCollapsed,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      if (isOverflow)
                        GestureDetector(
                          onTap: () {
                            setState(() => isExpanded = !isExpanded);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isExpanded ? 'less' : 'more',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        color: isLiked ? Colors.blue : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text("$likeCount"),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _openComments,
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined, size: 20),
                      const SizedBox(width: 4),
                      Text("$commentCount"),
                    ],
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.share_outlined, size: 20),
                    SizedBox(width: 4),
                    Text("Share"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
