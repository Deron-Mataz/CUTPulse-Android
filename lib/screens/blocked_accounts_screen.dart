import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class BlockedAccountsScreen extends StatelessWidget {
  const BlockedAccountsScreen({super.key});

  Future<void> _unblockUser(
    BuildContext context,
    String blockedUserId,
    String username,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username has been unblocked.'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock $username. Try again.'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) return doc.data();
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final blockedCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Accounts'),
        backgroundColor: Colors.blueAccent,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: blockedCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final blockedDocs = snapshot.data?.docs ?? [];

          if (blockedDocs.isEmpty) {
            return Center(
              child: Text(
                'No blocked accounts.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: blockedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final blockedUserId = blockedDocs[index].id;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserData(blockedUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.grey),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data;
                  final username = userData?['username'] ?? 'Unknown';
                  final profilePhoto = userData?['profilePhoto'] as String?;
                  final email = userData?['email'] ?? '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profilePhoto != null
                            ? NetworkImage(profilePhoto)
                            : null,
                        child: profilePhoto == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () =>
                            _unblockUser(context, blockedUserId, username),
                        child: const Text(
                          'Unblock',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
