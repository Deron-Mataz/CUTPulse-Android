import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'blocked_accounts_screen.dart';
import 'likes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  bool _darkMode = false;

  Future<void> _resetPassword() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      await _auth.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to ${user.email}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blueAccent),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            // Dark Mode Toggle //fix when done with all screens and features
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  "Dark Mode",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                },
                secondary: const Icon(Icons.dark_mode, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 12),

            _buildButton(
              icon: Icons.block,
              iconColor: Colors.redAccent,
              label: "Blocked Accounts",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BlockedAccountsScreen(),
                  ),
                );
              },
            ),

            _buildButton(
              icon: Icons.thumb_up,
              iconColor: Colors.blue,
              label: "My Likes",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LikesScreen()),
                );
              },
            ),

            _buildButton(
              icon: Icons.lock_reset,
              iconColor: Colors.orange,
              label: "Reset Password",
              onTap: _resetPassword,
            ),

            _buildButton(
              icon: Icons.logout,
              iconColor: Colors.red,
              label: "Log Out",
              onTap: _logout,
            ),

            const SizedBox(height: 24),

            if (user != null)
              Text(
                "Logged in as ${user.email}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
