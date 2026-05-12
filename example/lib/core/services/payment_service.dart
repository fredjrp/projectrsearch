import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PaymentService {
  // TODO: Replace with your Safaricom Sandbox credentials
  static const String _consumerKey = "YOUR_CONSUMER_KEY";
  static const String _consumerSecret = "YOUR_CONSUMER_SECRET";
  static const String _shortCode = "174379"; // Sandbox Shortcode
  static const String _passkey = "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"; // Sandbox Passkey
  
  static const String _authUrl = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials";
  static const String _stkPushUrl = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest";

  Future<String?> _getAccessToken() async {
    String credentials = base64Encode(utf8.encode("$_consumerKey:$_consumerSecret"));
    try {
      final response = await http.get(
        Uri.parse(_authUrl),
        headers: {"Authorization": "Basic $credentials"},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)["access_token"];
      }
    } catch (e) {
      print("Auth Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String callbackUrl,
  }) async {
    final token = await _getAccessToken();
    if (token == null) return {"success": false, "message": "Failed to get access token"};

    final timestamp = DateFormat("yyyyMMddHHmmss").format(DateTime.now());
    final password = base64Encode(utf8.encode("$_shortCode$_passkey$timestamp"));
    
    // Normalize phone number to 254...
    String formattedPhone = phoneNumber.startsWith("0") 
        ? "254${phoneNumber.substring(1)}" 
        : phoneNumber.replaceAll("+", "");

    final body = {
      "BusinessShortCode": _shortCode,
      "Password": password,
      "Timestamp": timestamp,
      "TransactionType": "CustomerPayBillOnline",
      "Amount": amount.toInt(),
      "PartyA": formattedPhone,
      "PartyB": _shortCode,
      "PhoneNumber": formattedPhone,
      "CallBackURL": callbackUrl,
      "AccountReference": "BoltClone",
      "TransactionDesc": "Ride Booking Payment"
    };

    try {
      final response = await http.post(
        Uri.parse(_stkPushUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );

      final result = json.decode(response.body);
      if (response.statusCode == 200 && result["ResponseCode"] == "0") {
        return {
          "success": true, 
          "checkoutRequestId": result["CheckoutRequestID"],
          "message": "STK Push initiated successfully"
        };
      } else {
        return {"success": false, "message": result["errorMessage"] ?? "STK Push failed"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Simulates a payment check for testing purposes
  Future<bool> simulatePaymentVerification(String checkoutRequestId) async {
    await Future.delayed(const Duration(seconds: 3));
    return true; // Always return true for demo
  }
}
