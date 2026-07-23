import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:surfspot/Theme/app_theme.dart';

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
    final isWide = AppBreakpoints.isTablet(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active_rounded, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Subscribe to Surf Notifications",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Get daily surf alerts at 9 AM if good conditions are expected at any point throughout the day. "
                    "Stay informed and never miss a perfect wave!\n"
                    "This is a free service, and you can unsubscribe anytime.",
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubscribed ? null : _subscribeToNotifications,
                          icon: Icon(_isSubscribed ? Icons.check_circle_rounded : Icons.notifications_rounded),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubscribed ? AppColors.good : colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          label: Text(_isSubscribed ? "Subscribed!" : "Subscribe"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubscribed ? _unsubscribeFromNotifications : null,
                          icon: const Icon(Icons.notifications_off_rounded),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.coral,
                            side: const BorderSide(color: AppColors.coral),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          label: const Text("Unsubscribe"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}