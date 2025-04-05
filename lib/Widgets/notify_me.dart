import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotifyMe extends StatefulWidget {
  const NotifyMe({super.key});

  @override
  State<NotifyMe> createState() => _NotifyMeState();
}

class _NotifyMeState extends State<NotifyMe> {
  bool _isSubscribed = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  // Get the FCM Token for this device
  void _getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token;

    if (kIsWeb) {
      token = await messaging.getToken(
        vapidKey: 'BFgj1qFNfDDHSMrdh0-yoiAp2QQc8pQQb-g0yakvA2olKfmpQ5vC629WZ1YFFOISsIvqvXuf1IeuqhHFyOqclP0',
      );
    } else {
      token = await messaging.getToken();
    }

    if (token != null) {
      setState(() {
        _fcmToken = token;
      });

      _checkSubscriptionStatus();
    }
  }

  void _checkSubscriptionStatus() async {
    if (_fcmToken == null) return;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('fcmToken', isEqualTo: _fcmToken)
        .get();

    setState(() {
      _isSubscribed = querySnapshot.docs.isNotEmpty;
    });
  }

  void _subscribeToNotifications() async {
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token not available')));
      return;
    }

    // Check if already subscribed
    QuerySnapshot existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('fcmToken', isEqualTo: _fcmToken)
        .get();

    if (existingUser.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('❌ You are already subscribed!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'fcmToken': _fcmToken,
      });

      setState(() {
        _isSubscribed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Successfully subscribed to notifications!'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ Failed to subscribe: $error'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _unsubscribeFromNotifications() async {
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token not available')));
      return;
    }

    try {
      // Find and delete the document with the matching fcmToken
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isEqualTo: _fcmToken)
          .get();

      for (var doc in querySnapshot.docs) {
        await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
      }

      setState(() {
        _isSubscribed = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Successfully unsubscribed!'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ Failed to unsubscribe: $error'),
            backgroundColor: Colors.red),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubscribed ? null : _subscribeToNotifications,
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
                      onPressed: _isSubscribed ? _unsubscribeFromNotifications : null,
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