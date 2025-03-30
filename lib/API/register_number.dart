import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> registerPhoneNumber(String token, String phoneNumber) async {
  try {
    final response = await http.post(
      Uri.parse("http://192.168.10.108:5000/register"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "phoneNumber": phoneNumber,
        "token": token,
      }),
    );
    if (response.statusCode == 200) {
      print("Phone number registered successfully");
    } else {
      print("Failed to register phone number: ${response.body}");
    }
  } catch(e) {
    print("Error sending phone number registration request: $e");
  }
}