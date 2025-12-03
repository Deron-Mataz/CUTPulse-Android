import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'set_up_profile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  String emailMessage = '';
  Color emailMessageColor = Colors.green;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //only CUT email can login
  bool _isCUTEmail(String email) {
    final lower = email.toLowerCase();
    return lower.endsWith('@stud.cut.ac.za') || lower.endsWith('@cut.ac.za');
  }

  //no duplication of emails
  void checkEmailExists(String email) {
    if (email.isEmpty) {
      setState(() {
        emailMessage = '';
      });
      return;
    }

    if (!_isCUTEmail(email)) {
      setState(() {
        emailMessage = 'Only CUT email addresses are allowed';
        emailMessageColor = Colors.red;
      });
    } else {
      setState(() {
        emailMessage = 'Email looks good';
        emailMessageColor = Colors.green;
      });
    }
  }

  bool isStrongPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    if (!_isCUTEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use your official CUT email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetUpProfilePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = e.code == 'email-already-in-use'
          ? 'Email already registered'
          : e.message ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
            colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => checkEmailExists(val.trim()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!_isCUTEmail(value.trim())) {
                          return 'Please use your official CUT email address';
                        }
                        return null;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('CUT Email', Icons.email),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        emailMessage,
                        style: GoogleFonts.poppins(
                          color: emailMessageColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (!isStrongPassword(value)) {
                          return 'Password must include uppercase, lowercase, number & special char';
                        }
                        return null;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        'Password',
                        Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(
                            () => passwordVisible = !passwordVisible,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !confirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(
                            () => confirmPasswordVisible =
                                !confirmPasswordVisible,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 80,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: isLoading ? null : _registerUser,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF2196F3),
                              strokeWidth: 2,
                            )
                          : Text(
                              "Register",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account? Login",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
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
