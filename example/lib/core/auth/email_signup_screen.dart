import 'package:flutter/material.dart';
import 'email_login_screen.dart';
import '../../student/student_dashboard.dart';
import '../../student/student_registration_screen.dart';
import '../../driver/driver_dashboard.dart';
import '../../driver/driver_registration_screen.dart';
import '../../driver/pending_verification_screen.dart';
import '../theme/stdeli_theme.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailSignupScreen extends StatefulWidget {
  final String appType;

  const EmailSignupScreen({Key? key, required this.appType}) : super(key: key);

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _validateAndSignup() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String name = _nameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'All fields are required');
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters long');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        role: widget.appType,
      );

      if (!mounted) return;

      if (widget.appType == 'student') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
          (route) => false,
        );
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
      setState(() => _errorMessage = e.toString());
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
                'Create account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: StDeliTheme.darkText),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign up with your email to get started.',
                style: TextStyle(fontSize: 16, color: StDeliTheme.greyText),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16),
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
                  onPressed: _isLoading ? null : _validateAndSignup,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EmailLoginScreen(appType: widget.appType)),
                    );
                  },
                  child: const Text('Already have an account? Login', style: TextStyle(color: StDeliTheme.primaryGreen)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
