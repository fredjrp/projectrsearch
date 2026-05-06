import 'package:flutter/material.dart';

class SosManagementScreen extends StatelessWidget {
  const SosManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Alert Management", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text("No active SOS alerts.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 8),
            Text("Your fleet is safe.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
