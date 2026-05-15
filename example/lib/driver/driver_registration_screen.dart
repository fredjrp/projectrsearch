import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/stdeli_theme.dart';
import '../core/services/auth_service.dart';
import '../core/services/sync_service.dart';
import 'pending_verification_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';
  final AuthService _authService = AuthService();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _licenseImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (_vehicleMakeController.text.isEmpty ||
        _vehicleModelController.text.isEmpty ||
        _contactController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all details.');
      return;
    }

    if (_licenseImage == null) {
      setState(() => _errorMessage = 'Please upload your license photo.');
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'You must agree to the Terms and Conditions.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      // 1. Upload License Image
      String licenseUrl = await _authService.uploadImage(
        _licenseImage!,
        'license_photos/$uid.jpg',
      );
      
      // If upload failed, queue for sync
      if (licenseUrl.startsWith('local:')) {
        final localPath = licenseUrl.replaceFirst('local:', '');
        await SyncService().addToQueue(
          uid: uid,
          localPath: localPath,
          storagePath: 'license_photos/$uid.jpg',
          collection: 'drivers',
          field: 'licensePhoto',
        );
      }
      
      // 2. Submit Data
      String makeModel = '${_vehicleMakeController.text} ${_vehicleModelController.text}';
      await _authService.submitDriverRegistration(
        uid: uid,
        vehicleMake: makeModel,
        licensePlate: _licensePlateController.text,
        phone: _contactController.text,
        licensePhotoPath: licenseUrl,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
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
        title: const Text('Driver Registration', style: TextStyle(color: Colors.black)),
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
              'Complete your profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: StDeliTheme.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide your vehicle details and contact info to proceed.',
              style: TextStyle(color: StDeliTheme.greyText),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _vehicleMakeController,
              decoration: const InputDecoration(labelText: 'Vehicle Make (e.g., Toyota)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _vehicleModelController,
              decoration: const InputDecoration(labelText: 'Vehicle Model (e.g., Prius)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _licensePlateController,
              decoration: const InputDecoration(labelText: 'License Plate Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone Number'),
            ),
            const SizedBox(height: 24),
            // Driver's License Upload Button
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  image: _licenseImage != null 
                    ? DecorationImage(image: FileImage(_licenseImage!), fit: BoxFit.cover, opacity: 0.3)
                    : null,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.camera_alt, color: StDeliTheme.primaryGreen, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _licenseImage == null ? 'Upload Driver\'s License Photo' : 'Change License Photo',
                      style: const TextStyle(color: StDeliTheme.primaryGreen, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (val) {
                    setState(() => _agreedToTerms = val ?? false);
                  },
                  activeColor: StDeliTheme.primaryGreen,
                ),
                const Expanded(
                  child: Text(
                    'I agree to the Terms and Conditions and Privacy Policy.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Submit for Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
