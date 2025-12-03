import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'Home_screen.dart'; // Make sure this import points to your HomeScreen file

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isPosting = false;
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      setState(() {
        profilePhotoUrl = doc.data()?['profilePhoto'] as String?;
      });
    } catch (e) {
      debugPrint("Error loading profile photo: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createPost() async {
    if (_textController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add text or image to post")),
      );
      return;
    }

    setState(() => isPosting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      String? imageUrl;

      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'posts/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}',
        );
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      final postData = {
        'postId': postRef.id,
        'userId': currentUser.uid,
        'username': currentUser.displayName ?? 'User',
        'profilePhoto': profilePhotoUrl ?? '',
        'textContent': _textController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
      };
      await postRef.set(postData);

      setState(() {
        isPosting = false;
        _textController.clear();
        _selectedImage = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post created successfully!")),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => isPosting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to create post: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              "Create Post",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: isPosting ? null : _createPost,
                child: Text(
                  "Post",
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profilePhotoUrl != null
                          ? NetworkImage(profilePhotoUrl!)
                          : null,
                      child: profilePhotoUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "Add Media (Optional)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isPosting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
