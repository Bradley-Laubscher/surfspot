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
  final bool _isSubscribed = false;
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

  void _subscribeToNotifications() async {
    String userId = _userId.text;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a userId')));
      return;
    }

    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FCM token not available')));
      return;
    }

    // save the token to FireStore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmToken': _fcmToken,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _userId,
          decoration: const InputDecoration(labelText: 'Enter UserId'),
        ),
        ElevatedButton(
          onPressed: _subscribeToNotifications,
          child: _isSubscribed ? const Text("Subscribed!") : const Text("Subscribe to Notifications"),
        ),
      ],
    );
  }
}