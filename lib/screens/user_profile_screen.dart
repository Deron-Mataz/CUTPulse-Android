import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/post_widget.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late Future<Map<String, dynamic>> _profileDataFuture;
  bool isFollowing = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    Map<String, dynamic> data = {};

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      data['userData'] = userDoc.data();

      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();
      data['posts'] = postSnapshot.docs.map((doc) => doc.data()).toList();

      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .get();
      data['followersCount'] = followersSnapshot.docs.length;

      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();
      data['followingCount'] = followingSnapshot.docs.length;

      final isFollowingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUser.uid)
          .get();
      isFollowing = isFollowingSnapshot.exists;
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
    }

    return data;
  }

  void _toggleFollow() async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    if (isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Unfollow user?"),
          content: const Text("Are you sure you want to unfollow this user?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Unfollow"),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await userRef.collection('followers').doc(currentUser.uid).delete();
      await currentUserRef.collection('following').doc(widget.userId).delete();
    } else {
      await userRef.collection('followers').doc(currentUser.uid).set({
        'followedAt': FieldValue.serverTimestamp(),
      });
      await currentUserRef.collection('following').doc(widget.userId).set({
        'followedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      isFollowing = !isFollowing;
      _profileDataFuture = _fetchProfileData();
    });
  }

  void _showUserMenu() async {
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
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text("Block"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Block"),
                      content: const Text(
                        "Are you sure you want to block this user? You won't see their posts anymore.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Block"),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('blockedUsers')
                      .doc(widget.userId)
                      .set({'blockedAt': FieldValue.serverTimestamp()});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User blocked.")),
                  );
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text("Report"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportUserSheet();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showReportUserSheet() {
    String selectedReason = '';
    final TextEditingController otherController = TextEditingController();
    final TextEditingController identityController = TextEditingController();

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
                      "Report User",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Select a reason for reporting this user:",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      "Spam",
                      "Inappropriate Content",
                      "Pretending to be someone else",
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
                    if (selectedReason == "Pretending to be someone else")
                      TextField(
                        controller: identityController,
                        decoration: const InputDecoration(
                          labelText: "Whose identity is being stolen?",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (selectedReason == "Other")
                      TextField(
                        controller: otherController,
                        decoration: const InputDecoration(
                          labelText: "Please describe the issue",
                          border: OutlineInputBorder(),
                        ),
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
                                : selectedReason ==
                                      "Pretending to be someone else"
                                ? identityController.text.trim()
                                : selectedReason;

                            if (reason.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please provide a reason."),
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
                                    'reportType': 'user',
                                    'reportedId': widget.userId,
                                    'reportedBy': currentUser.uid,
                                    'reason': reason,
                                    'status': 'Pending',
                                    'timestamp': FieldValue.serverTimestamp(),
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

  Widget _buildStatItem(String label, String number) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: Colors.grey[600])),
      ],
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Error loading profile"));
          }

          final userData = snapshot.data!['userData'] ?? {};
          final userPosts = snapshot.data!['posts'] ?? [];
          final followersCount = snapshot.data!['followersCount'] ?? 0;
          final followingCount = snapshot.data!['followingCount'] ?? 0;

          final profilePhoto = userData['profilePhoto'] as String?;
          final backgroundPhoto = userData['backgroundPhoto'] as String?;
          final displayName = userData['displayName'] ?? '';

          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 180 + statusBarHeight,
                    width: double.infinity,
                    padding: EdgeInsets.only(top: statusBarHeight),
                    decoration: BoxDecoration(
                      image: backgroundPhoto != null
                          ? DecorationImage(
                              image: NetworkImage(backgroundPhoto),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: backgroundPhoto == null
                          ? Colors.blueGrey[200]
                          : null,
                    ),
                  ),
                  Positioned(
                    top: statusBarHeight + 8,
                    left: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: 16,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profilePhoto != null
                          ? NetworkImage(profilePhoto)
                          : null,
                      child: profilePhoto == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    right: 16,
                    left: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Posts", userPosts.length.toString()),
                        _buildStatItem("Followers", followersCount.toString()),
                        _buildStatItem("Following", followingCount.toString()),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displayName.isNotEmpty)
                          Text(
                            displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          userData['name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userData['username'] != null
                              ? '@${userData['username']}'
                              : '',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData['bio'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (currentUser.uid != widget.userId)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing
                                        ? Colors.grey
                                        : Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    isFollowing ? 'Following' : 'Follow',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _showUserMenu,
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        ...userPosts.map((post) => PostWidget(postData: post)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
