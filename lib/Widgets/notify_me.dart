import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surfspot/API/register_number.dart';
import 'package:surfspot/API/send_notification.dart';
import 'package:surfspot/Providers/location_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotifyMe extends StatefulWidget {
  const NotifyMe({super.key});

  @override
  State<NotifyMe> createState() => _NotifyMeState();
}

class _NotifyMeState extends State<NotifyMe> {
  TextEditingController _phoneController = TextEditingController();
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

  void _subscribeToNotifications() async {
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
      return;
    }

    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FCM token not available')));
      return;
    }

    // register the phone number
    registerPhoneNumber(_fcmToken!, phoneNumber);

    // Check surf conditions from LocationProvider
    bool isGoodDay = Provider.of<LocationProvider>(context, listen: false).isGoodSurfDay;

    if (isGoodDay) {
      // Send push notification
      _sendPushNotification(phoneNumber);
      setState(() {
        _isSubscribed = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surf conditions are not good today')));
    }
  }

  void _sendPushNotification(phoneNumber) {
    // Send the notification via your backend here
    sendPushNotification(phoneNumber, "SurfSpot", "Waves are good!");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(labelText: 'Enter Phone Number'),
        ),
        ElevatedButton(
          onPressed: _subscribeToNotifications,
          child: _isSubscribed ? Text("Subscribed!") : Text("Subscribe to Notifications"),
        ),
      ],
    );
  }
}