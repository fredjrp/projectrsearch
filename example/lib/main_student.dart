import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/bolt_theme.dart';
import 'core/auth/login_screen.dart';
import 'core/widgets/skeleton_loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudentApp());
}

class StudentApp extends StatefulWidget {
  const StudentApp({Key? key}) : super(key: key);

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  bool _initialized = false;
  bool _error = false;

  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint("Firebase init error: $e");
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Failed to initialize Firebase. Check your configuration."),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SkeletonLoading(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Rider App',
      theme: BoltTheme.themeData,
      home: const LoginScreen(appType: 'student'),
    );
  }
}
