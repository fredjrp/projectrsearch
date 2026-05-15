import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'onboarding_screen.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Trigger background sync for any pending image uploads
  SyncService().syncNow();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navigation App',
      theme: ThemeData(
        fontFamily: 'Mulish', // Using your onboarding font
      ),
      home: const OnboardingScreen(),
      routes: {
        '/navigation': (context) => const SampleNavigationApp(),
      },
    );
  }
}
