import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendPushNotification(String phoneNumber, String title, String body) async {
  try {
    final response = await http.post(
      Uri.parse("http://192.168.10.108:5000/sendNotification"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phoneNumber": phoneNumber,
        "title": title,
        "body": body,
      }),
    );
    if (response.statusCode == 200) {
      print("Notification sent successfully");
    } else {
      print("Failed to send notification: ${response.body}");
    }
  } catch(e) {
    print("Error sending notification request: $e");
  }
}