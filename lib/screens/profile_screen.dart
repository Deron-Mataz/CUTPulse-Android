import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/post_widget.dart';
import 'edit_profile_screen.dart';
import 'upload_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late Future<Map<String, dynamic>> _profileDataFuture;
  int _selectedIndex = 3;

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
          .doc(currentUser.uid)
          .get();
      data['userData'] = userDoc.data() ?? {};

      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();
      data['posts'] = postSnapshot.docs.map((doc) => doc.data()).toList();

      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('followers')
          .get();
      data['followersCount'] = followersSnapshot.docs.length;

      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .get();
      data['followingCount'] = followingSnapshot.docs.length;
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
    }

    return data;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) {
        _profileDataFuture = _fetchProfileData();
      }
    });
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 28,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (!isSelected) const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Settings",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 25, thickness: 1),
              _buildSettingsItem(Icons.block, "Blocked Accounts", () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Blocked Accounts tapped")),
                );
              }),
              _buildSettingsItem(Icons.help_outline, "Help", () {
                Navigator.pop(context);

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Help tapped")));
              }),
              _buildSettingsItem(Icons.no_accounts, "Disable Account", () {
                Navigator.pop(context);
                // Future: implement disable logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Disable Account tapped")),
                );
              }),
              const Divider(),
              _buildSettingsItem(Icons.logout, "Log Out", () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const UploadScreen(),
      _buildProfileView(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.search, 1),
            _buildNavItem(Icons.add_box_outlined, 2),
            _buildNavItem(Icons.person, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text("Error loading profile"));
        }

        final data = snapshot.data!;
        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          data['userData'] ?? {},
        );
        final List<Map<String, dynamic>> userPosts = (data['posts'] ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final followersCount = data['followersCount'] ?? 0;
        final followingCount = data['followingCount'] ?? 0;

        final profilePhoto = userData['profilePhoto'] as String?;
        final backgroundPhoto = userData['backgroundPhoto'] as String?;

        return ListView(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[200],
                    image: backgroundPhoto != null
                        ? DecorationImage(
                            image: NetworkImage(backgroundPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: backgroundPhoto == null
                      ? const Icon(Icons.image, size: 80, color: Colors.white70)
                      : null,
                ),
                Positioned(
                  bottom: -50,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              "Posts",
                              userPosts.length.toString(),
                            ),
                            _buildStatItem(
                              "Followers",
                              followersCount.toString(),
                            ),
                            _buildStatItem(
                              "Following",
                              followingCount.toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final updated = await Navigator.push(
                              //fix error when updating profile. !!
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(userData: userData),
                              ),
                            );
                            if (updated == true) {
                              final refreshedData = _fetchProfileData();
                              setState(() {
                                _profileDataFuture = refreshedData;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Edit Profile",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            userPosts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          "You have no posts yet. Create your first post!",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            "Create Post",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: userPosts
                        .map(
                          (post) => PostWidget(
                            postData: Map<String, dynamic>.from(post),
                          ),
                        )
                        .toList(),
                  ),
          ],
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
}
