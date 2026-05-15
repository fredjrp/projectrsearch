import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_signup_screen.dart';
import 'email_login_screen.dart';
import '../../student/student_dashboard.dart';
import '../../student/student_registration_screen.dart';
import '../../driver/driver_dashboard.dart';
import '../../driver/driver_registration_screen.dart';
import '../../driver/pending_verification_screen.dart';
import '../theme/stdeli_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String appType; // 'student' or 'driver'

  const LoginScreen({Key? key, required this.appType}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _codeSent = false;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _validateAndSendCode() async {
    String phone = _phoneController.text.trim();
    RegExp basicKenyan = RegExp(r'^(\+254|0)?(7|1)\d{8}$');

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number');
      return;
    }
    
    if (!basicKenyan.hasMatch(phone)) {
      setState(() => _errorMessage = 'Please enter a valid Kenyan phone number (e.g. 0712345678)');
      return;
    }
    
    // Convert to E.164 format for Firebase if it starts with 0
    if (phone.startsWith('0')) {
      phone = '+254${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+$phone';
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    await _authService.sendOtp(
      phoneNumber: phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _verifySmsCode() async {
    if (_smsController.text.length < 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.verifyOtp(smsCode: _smsController.text);
      await _handlePostLoginRouting();
    } catch (e) {
      setState(() => _errorMessage = 'Invalid code or verification failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePostLoginRouting() async {
    if (!mounted) return;

    if (widget.appType == 'student') {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      bool isProfileComplete = await _authService.isStudentProfileComplete(uid);
      
      if (!mounted) return;
      
      if (isProfileComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
        );
      }
    } else {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String status = await _authService.checkDriverStatus(uid);
      
      if (!mounted) return;
      
      if (status == 'new') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverRegistrationScreen()),
        );
      } else if (status == 'pending') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverDashboard()),
        );
      }
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent ? 'Enter code' : 'Enter your number',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: BoltTheme.darkText),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent 
                  ? 'We sent a 6-digit code to ${_phoneController.text}'
                  : 'We will send you a code to verify your mobile number.',
                style: const TextStyle(fontSize: 16, color: BoltTheme.greyText),
              ),
              const SizedBox(height: 32),
              
              if (!_codeSent)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+254 700 000 000',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                )
              else
                TextField(
                  controller: _smsController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit SMS code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.security),
                  ),
                ),
                
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
                ),
                
              const Spacer(),
              
              if (!_codeSent)
                Column(
                  children: [
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EmailSignupScreen(appType: widget.appType)),
                          );
                        },
                        child: const Text('Don\'t have an account? Sign up', style: TextStyle(color: BoltTheme.primaryGreen)),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EmailLoginScreen(appType: widget.appType)),
                          );
                        },
                        child: const Text('Login with Email', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
                
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_codeSent ? _verifySmsCode : _validateAndSendCode),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : Text(_codeSent ? 'Verify Code' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
