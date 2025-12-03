import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/profile_screen.dart';
import '../screens/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final currentUser = FirebaseAuth.instance.currentUser!;

  List<Map<String, dynamic>> filteredAccounts = [];
  List<Map<String, dynamic>> recentAccounts = [];
  List<Map<String, dynamic>> allAccounts = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = snapshot.docs
        .map(
          (doc) => {
            "userId": doc.id,
            "username": doc.data()['username'] ?? '',
            "name": doc.data()['name'] ?? '',
            "profilePhoto": doc.data()['profilePhoto'],
          },
        )
        .toList();

    final uniqueUsers = {for (var u in users) u['userId']: u}.values.toList();

    setState(() {
      allAccounts = uniqueUsers;
      filteredAccounts = [];
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredAccounts = [];
      });
      return;
    }

    setState(() {
      filteredAccounts = allAccounts
          .where(
            (acc) =>
                acc['username'].toLowerCase().contains(query) ||
                acc['name'].toLowerCase().contains(query),
          )
          .toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _onUserTap(Map<String, dynamic> user) {
    if (!recentAccounts.any((acc) => acc['userId'] == user['userId'])) {
      setState(() {
        recentAccounts.insert(0, user);
      });
    }

    if (user['userId'] == currentUser.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: user['userId']),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 16,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Search",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: _clearSearch,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (recentAccounts.isNotEmpty &&
                      _searchController.text.isEmpty) ...[
                    Text(
                      "Recent",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentAccounts.length,
                        itemBuilder: (context, index) {
                          final acc = recentAccounts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: GestureDetector(
                              onTap: () => _onUserTap(acc),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: acc['profilePhoto'] != null
                                        ? NetworkImage(acc['profilePhoto'])
                                        : null,
                                    child: acc['profilePhoto'] == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 28,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    acc['username'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_searchController.text.isNotEmpty) ...[
                    Text(
                      "Suggestions",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ), //

                    const SizedBox(height: 8),
                    ...filteredAccounts.map((acc) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            backgroundImage: acc['profilePhoto'] != null
                                ? NetworkImage(acc['profilePhoto'])
                                : null,
                            child: acc['profilePhoto'] == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(
                            acc['username'] ?? '',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            acc['name'] ?? '',
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                          onTap: () => _onUserTap(acc),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
