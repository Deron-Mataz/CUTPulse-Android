import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import '../firebase_options.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    //only navigate to screen after connection
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully!');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
    }

    // Wait 3 seconds after initialization
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to LoginScreen safely
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color.fromARGB(255, 89, 90, 53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(size: const Size(120, 120), painter: LogoPainter()),
              const SizedBox(height: 20),
              Text(
                "CUTPulse",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Connect. Collaborate. Grow.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
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

    final pulsePath = Path();
    pulsePath.moveTo(20, size.height / 2);
    pulsePath.lineTo(40, size.height / 2);
    pulsePath.lineTo(50, size.height / 3);
    pulsePath.lineTo(70, size.height * 2 / 3);
    pulsePath.lineTo(100, size.height / 2);
    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
