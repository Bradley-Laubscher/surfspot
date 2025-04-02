import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotifyMe extends StatefulWidget {
  const NotifyMe({super.key});

  @override
  State<NotifyMe> createState() => _NotifyMeState();
}

class _NotifyMeState extends State<NotifyMe> {
  final TextEditingController _userId = TextEditingController();
  bool _isSubscribed = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  void _getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    setState(() {
      _fcmToken = token;
    });
  }

  // Method to check if the user is already subscribed using their fcmToken
  Future<bool> _checkIfAlreadySubscribed() async {
    // Search for the user document by fcmToken
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('fcmToken', isEqualTo: _fcmToken)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Method to check if the userId exists in Firestore
  Future<bool> _checkUserExists(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists;
  }

  void _subscribeToNotifications() async {
    String userId = _userId.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a User ID')));
      return;
    }

    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FCM token not available')));
      return;
    }

    // Check if the user is already subscribed
    bool alreadySubscribed = await _checkIfAlreadySubscribed();
    if (alreadySubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ You are already subscribed!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Check if the userId already exists in the database
    bool userExists = await _checkUserExists(userId);
    if (userExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ This User ID is already subscribed! Please use a different User ID.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Save the token and userId to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': _fcmToken,
        'userId': userId,  // Storing the userId to verify during unsubscribe
      }, SetOptions(merge: true));

      setState(() {
        _isSubscribed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Successfully subscribed to notifications!'), backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to subscribe: $error'), backgroundColor: Colors.red),
      );
    }
  }

  void _unsubscribeFromNotifications() async {
    String userId = _userId.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a User ID')));
      return;
    }

    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FCM token not available')));
      return;
    }

    try {
      // Retrieve user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      // Check if the user exists and if the stored fcmToken matches the current fcmToken
      if (userDoc.exists && userDoc['fcmToken'] == _fcmToken) {
        // If the fcmToken matches, delete the document
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();

        setState(() {
          _isSubscribed = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Successfully unsubscribed from notifications!'), backgroundColor: Colors.green),
        );
      } else {
        // If the fcmToken doesn't match, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ You're trying to unsubscribe another user! Make sure you typed in your User ID correctly"), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to unsubscribe: $error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Subscribe to Surf Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Get daily surf alerts at 9 AM if good conditions are expected at any point throughout the day. "
                    "Stay informed and never miss a perfect wave!\n"
                    "This is a free service, and you can unsubscribe anytime.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userId,
                decoration: InputDecoration(
                  labelText: 'Enter User ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _subscribeToNotifications,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: _isSubscribed ? Colors.green : Colors.blue,
                      ),
                      child: Text(
                        _isSubscribed ? "Subscribed!" : "Subscribe",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _unsubscribeFromNotifications,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        "Unsubscribe",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}