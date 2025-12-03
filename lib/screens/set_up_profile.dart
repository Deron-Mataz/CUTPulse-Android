import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'profile_screen.dart';

class SetUpProfilePage extends StatefulWidget {
  const SetUpProfilePage({super.key});

  @override
  State<SetUpProfilePage> createState() => _SetUpProfilePageState();
}

class _SetUpProfilePageState extends State<SetUpProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  File? profilePhoto;
  File? backgroundPhoto;
  bool isLoading = false;
  bool usernameAvailable = true;
  String usernameMessage = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickAndCropImage(bool isProfile) async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (pickedFile != null) {
                  await _cropAndSetImage(pickedFile.path, isProfile);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (pickedFile != null) {
                  await _cropAndSetImage(pickedFile.path, isProfile);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropAndSetImage(String path, bool isProfile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: isProfile
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : const CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isProfile ? 'Crop Profile Picture' : 'Crop Background',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: isProfile ? 'Crop Profile Picture' : 'Crop Background',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        if (isProfile) {
          profilePhoto = File(croppedFile.path);
        } else {
          backgroundPhoto = File(croppedFile.path);
        }
      });
    }
  }

  Future<void> checkUsername(String username) async {
    if (username.trim().isEmpty) {
      setState(() {
        usernameAvailable = false;
        usernameMessage = '';
      });
      return;
    }

    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .get();

    setState(() {
      if (result.docs.isNotEmpty) {
        usernameAvailable = false;
        usernameMessage = 'Username is already taken';
      } else {
        usernameAvailable = true;
        usernameMessage = 'Username is available';
      }
    });
  }

  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose another username'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? profileUrl;
      String? backgroundUrl;

      if (profilePhoto != null) {
        profileUrl = await _uploadImage(
          profilePhoto!,
          'profile_photos/${user.uid}.jpg',
        );
      }
      if (backgroundPhoto != null) {
        backgroundUrl = await _uploadImage(
          backgroundPhoto!,
          'background_photos/${user.uid}.jpg',
        );
      }

      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'username': usernameController.text.trim().toLowerCase(),
        'bio': bioController.text.trim(),
        'profilePhoto': profileUrl,
        'backgroundPhoto': backgroundUrl,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving profile'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "Set Up Your Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => _pickAndCropImage(false),
                    child: Stack(
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            image: backgroundPhoto != null
                                ? DecorationImage(
                                    image: FileImage(backgroundPhoto!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: backgroundPhoto == null
                              ? const Icon(
                                  Icons.image,
                                  color: Colors.white54,
                                  size: 50,
                                )
                              : null,
                        ),
                        const Positioned(
                          right: 8,
                          bottom: 8,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => _pickAndCropImage(true),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: profilePhoto != null
                          ? ClipOval(
                              child: Image.file(
                                profilePhoto!,
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 50,
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Name', Icons.person),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: usernameController,
                    onChanged: (val) => checkUsername(val.trim()),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Username',
                      Icons.alternate_email,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a username' : null,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      usernameMessage,
                      style: GoogleFonts.poppins(
                        color: usernameAvailable ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: bioController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: _inputDecoration('Bio', Icons.info_outline),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 80,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: isLoading ? null : _saveProfile,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF2196F3),
                            strokeWidth: 2,
                          )
                        : Text(
                            "Continue",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2196F3),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }
}
