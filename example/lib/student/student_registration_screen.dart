import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/stdeli_theme.dart';
import '../core/services/auth_service.dart';
import '../core/services/sync_service.dart';
import 'student_dashboard.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;
  String _errorMessage = '';
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _institutionController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all details.');
      return;
    }

    if (_imageFile == null) {
      setState(() => _errorMessage = 'Please upload a profile picture.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      
      // 1. Upload Image (with fallback)
      String imageUrl = await _authService.uploadImage(
        _imageFile!,
        'profile_pics/$uid.jpg',
      );
      
      // If upload failed and returned a local path, queue it for sync
      if (imageUrl.startsWith('local:')) {
        final localPath = imageUrl.replaceFirst('local:', '');
        await SyncService().addToQueue(
          uid: uid,
          localPath: localPath,
          storagePath: 'profile_pics/$uid.jpg',
          collection: 'users',
          field: 'profileImage',
        );
      }
      
      // 2. Submit Data
      await _authService.submitStudentRegistration(
        uid: uid,
        fullName: _nameController.text,
        phone: _phoneController.text,
        institution: _institutionController.text,
        profileImageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: StDeliTheme.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'This information helps drivers identify and contact you.',
              style: TextStyle(color: StDeliTheme.greyText),
            ),
            const SizedBox(height: 32),
            
            // Profile Picture Picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: StDeliTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: 'School / Institution / Workplace',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 32),
            
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
              
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StDeliTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Complete Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
