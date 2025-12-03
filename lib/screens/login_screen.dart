import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cutpulse/screens/profile_screen.dart';
import 'package:cutpulse/screens/terms_conditions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  bool isValidCUTEmail(String email) {
    return email.endsWith('@cut.ac.za') || email.endsWith('@stud.cut.ac.za');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: LogoPainter(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome Back!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Login to continue",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    _buildTextFormField(
                      controller: emailController,
                      label: "Email",
                      icon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!isValidCUTEmail(value.trim())) {
                          return 'Please enter a valid CUT email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        labelText: "Password",
                        labelStyle: GoogleFonts.poppins(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                      onPressed: isLoading ? null : _loginUser,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF3F51B5),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                color: Color(0xFF3F51B5),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TermsAndConditionsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Don't have an account? Register",
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

  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String message = '';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else {
          message = e.message ?? 'Login failed';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: const Center(
        child: Text("Forgot Password functionality will be added later."),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, Colors.lightBlueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ),
    );
    canvas.drawPath(path, paint);

    final pulsePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final points = [
      Offset(20, size.height / 2),
      Offset(40, size.height / 2),
      Offset(50, size.height / 3),
      Offset(70, size.height * 2 / 3),
      Offset(100, size.height / 2),
    ];

    final pulseWidth = points.last.dx - points.first.dx;
    final offsetX = (size.width - pulseWidth) / 2 - points.first.dx;

    final shiftedPoints = points.map((p) => p.translate(offsetX, 0)).toList();

    final pulsePath = Path()..moveTo(shiftedPoints[0].dx, shiftedPoints[0].dy);
    for (int i = 1; i < shiftedPoints.length; i++) {
      pulsePath.lineTo(shiftedPoints[i].dx, shiftedPoints[i].dy);
    }

    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
