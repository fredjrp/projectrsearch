import 'package:flutter/material.dart';
import 'email_signup_screen.dart';
import '../../student/student_dashboard.dart';
import '../../driver/driver_dashboard.dart';
import '../theme/bolt_theme.dart';

class LoginScreen extends StatefulWidget {
  final String appType; // 'student' or 'driver'

  const LoginScreen({Key? key, required this.appType}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  bool _codeSent = false;
  String _errorMessage = '';

  void _validateAndSendCode() {
    String phone = _phoneController.text.trim();
    // Simple Kenyan phone validation
    // Either starts with 07, 01, 254, +254 and has correct length
    RegExp kenyanPhoneRegExp = RegExp(r'^(?:254|\+254|0)?(7(?:(?:[129][0-9])|(?:0[0-8])|(4[0-1]))[0-9]{6}|1(?:[1][0-1])[0-9]{6})$');
    
    // Looser regex just for mockup purposes if needed, but let's stick to a robust one
    RegExp basicKenyan = RegExp(r'^(\+254|0)?(7|1)\d{8}$');

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number');
      return;
    }
    
    if (!basicKenyan.hasMatch(phone)) {
      setState(() => _errorMessage = 'Please enter a valid Kenyan phone number (e.g. 0712345678)');
      return;
    }

    setState(() {
      _errorMessage = '';
      _codeSent = true;
    });

    // TODO: Integrate actual FirebaseAuth verifyPhoneNumber
  }

  void _verifySmsCode() {
    if (_smsController.text.length < 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit code');
      return;
    }

    // TODO: Verify with Firebase auth credentials
    // Mock success routing
    if (widget.appType == 'student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverDashboard()),
      );
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
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: BoltTheme.darkText,
                ),
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
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                
              const Spacer(),
              
              if (!_codeSent)
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmailSignupScreen(appType: widget.appType),
                        ),
                      );
                    },
                    child: const Text('Or sign up with email', style: TextStyle(color: BoltTheme.primaryGreen)),
                  ),
                ),
                
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _codeSent ? _verifySmsCode : _validateAndSendCode,
                  child: Text(_codeSent ? 'Verify Code' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
