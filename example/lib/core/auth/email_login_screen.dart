import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../student/student_dashboard.dart';
import '../../student/student_registration_screen.dart';
import '../../driver/driver_dashboard.dart';
import '../../driver/driver_registration_screen.dart';
import '../../driver/pending_verification_screen.dart';
import '../theme/bolt_theme.dart';
import '../services/auth_service.dart';

class EmailLoginScreen extends StatefulWidget {
  final String appType;

  const EmailLoginScreen({Key? key, required this.appType}) : super(key: key);

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (widget.appType == 'student') {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        bool isProfileComplete = await _authService.isStudentProfileComplete(uid);
        
        if (!mounted) return;
        
        if (isProfileComplete) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
            (route) => false,
          );
        }
      } else {
        // Driver flow
        String uid = FirebaseAuth.instance.currentUser!.uid;
        String status = await _authService.checkDriverStatus(uid);
        
        if (!mounted) return;
        
        if (status == 'new') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DriverRegistrationScreen()),
            (route) => false,
          );
        } else if (status == 'pending') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DriverDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: BoltTheme.darkText),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to continue with your account.',
                style: TextStyle(fontSize: 16, color: BoltTheme.greyText),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
