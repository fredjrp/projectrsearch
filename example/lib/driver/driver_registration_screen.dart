import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/bolt_theme.dart';
import '../core/services/auth_service.dart';
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
  
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String _errorMessage = '';
  final AuthService _authService = AuthService();

  Future<void> _submitRegistration() async {
    if (_vehicleMakeController.text.isEmpty ||
        _vehicleModelController.text.isEmpty ||
        _licensePlateController.text.isEmpty ||
        _contactController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all details.');
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
      // Combine Make and Model for simplicity in the service layer
      String makeModel = '${_vehicleMakeController.text} ${_vehicleModelController.text}';
      
      await _authService.submitDriverRegistration(
        uid: uid,
        vehicleMake: makeModel,
        licensePlate: _licensePlateController.text,
        phone: _contactController.text,
        licensePhotoPath: 'pending_upload', // Placeholder for now
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BoltTheme.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide your vehicle details and contact info to proceed.',
              style: TextStyle(color: BoltTheme.greyText),
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
            // Mock Driver's License Upload Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: const [
                  Icon(Icons.camera_alt, color: BoltTheme.primaryGreen, size: 40),
                  SizedBox(height: 8),
                  Text('Upload Driver\'s License Photo', style: TextStyle(color: BoltTheme.primaryGreen)),
                ],
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
                  activeColor: BoltTheme.primaryGreen,
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
