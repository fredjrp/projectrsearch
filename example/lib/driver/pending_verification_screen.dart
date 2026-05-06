import 'package:flutter/material.dart';
import '../core/theme/bolt_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/auth/login_screen.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen(appType: 'driver')),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BoltTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 64,
                  color: BoltTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verification Pending',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BoltTheme.darkText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your documents have been submitted successfully. Our admin team is currently reviewing your profile.\n\nYou will be able to start driving once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: BoltTheme.greyText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // In a real app, you might want to refresh the user data
                  // to check if status changed. For now, it tells them to wait.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Still pending verification. Check back later!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: BoltTheme.primaryGreen,
                  side: const BorderSide(color: BoltTheme.primaryGreen),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Refresh Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
