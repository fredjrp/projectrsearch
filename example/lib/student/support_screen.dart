import 'package:flutter/material.dart';
import '../core/theme/stdeli_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Support", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How can we help you?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildSupportItem(context, Icons.chat_bubble_outline, "Live Chat", "Typical response time: 2 mins"),
            _buildSupportItem(context, Icons.email_outlined, "Email Support", "Typical response time: 2 hours"),
            _buildSupportItem(context, Icons.phone_outlined, "Call Emergency", "24/7 dedicated security line"),
            const SizedBox(height: 40),
            const Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text("How do I cancel a ride?"), trailing: Icon(Icons.add)),
                  ListTile(title: Text("M-Pesa payment failed?"), trailing: Icon(Icons.add)),
                  ListTile(title: Text("Lost an item?"), trailing: Icon(Icons.add)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: StDeliTheme.primaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {},
      ),
    );
  }
}
