import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Checking Firebase connection to app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  runApp(const CUTPulseApp());
}

//Navigate to Splash screen only after successful connection with firebase
class CUTPulseApp extends StatelessWidget {
  const CUTPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUTPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
