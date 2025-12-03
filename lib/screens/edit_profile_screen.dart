import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  File? profileImage;
  File? backgroundImage;
  bool isLoading = false;
  bool usernameAvailable = true;
  bool checkingUsername = false;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      nameController.text = widget.userData!['name'] ?? '';
      usernameController.text = widget.userData!['username'] ?? '';
      bioController.text = widget.userData!['bio'] ?? '';
    }
    usernameController.addListener(_checkUsername);
  }

  @override
  void dispose() {
    usernameController.removeListener(_checkUsername);
    usernameController.dispose();
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfile) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  setState(
                    () => isProfile
                        ? profileImage = File(picked.path)
                        : backgroundImage = File(picked.path),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(
                    () => isProfile
                        ? profileImage = File(picked.path)
                        : backgroundImage = File(picked.path),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  bool _isValidUsername(String username) {
    final pattern = RegExp(r'^[a-zA-Z0-9_.]{3,}$');
    return pattern.hasMatch(username);
  }

  Future<void> _checkUsername() async {
    final username = usernameController.text.trim();
    if (username.isEmpty || !_isValidUsername(username)) {
      setState(() {
        usernameAvailable = true;
        checkingUsername = false;
      });
      return;
    }

    setState(() => checkingUsername = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    bool taken = snapshot.docs.any((doc) => doc.id != currentUid);

    setState(() {
      usernameAvailable = !taken;
      checkingUsername = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    if (!_isValidUsername(username)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid username format.')));
      return;
    }
    if (!usernameAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username already taken.')));
      return;
    }

    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    String? profileUrl = widget.userData?['profilePhoto'];
    String? bgUrl = widget.userData?['backgroundPhoto'];

    if (profileImage != null) {
      profileUrl = await _uploadImage(
        profileImage!,
        'profiles/$uid/profile.jpg',
      );
    }
    if (backgroundImage != null) {
      bgUrl = await _uploadImage(
        backgroundImage!,
        'profiles/$uid/background.jpg',
      );
    }

    await userDoc.set({
      'name': nameController.text.trim(),
      'username': username,
      'bio': bioController.text.trim(),
      'profilePhoto': profileUrl,
      'backgroundPhoto': bgUrl,
    }, SetOptions(merge: true));

    setState(() => isLoading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(true),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  profileImage!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              )
                            : widget.userData?['profilePhoto'] != null
                            ? ClipOval(
                                child: Image.network(
                                  widget.userData!['profilePhoto'],
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              )
                            : const Icon(Icons.person, size: 50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: backgroundImage != null
                              ? DecorationImage(
                                  image: FileImage(backgroundImage!),
                                  fit: BoxFit.cover,
                                )
                              : widget.userData?['backgroundPhoto'] != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.userData!['backgroundPhoto'],
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            backgroundImage == null &&
                                widget.userData?['backgroundPhoto'] == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        suffixIcon: checkingUsername
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : usernameController.text.isEmpty
                            ? null
                            : Icon(
                                usernameAvailable
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: usernameAvailable
                                    ? Colors
                                          .green //good
                                    : Colors.red, //bad..not availablr
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a username';
                        }
                        if (!_isValidUsername(value.trim())) {
                          return 'At least 3 chars, letters, numbers, _ or . only';
                        }
                        if (!usernameAvailable) return 'Username already taken';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
