# surfspot

A surf forecast application built using Dart and Flutter.

The application makes use of the Open-Meteo weather API's to gather and display surf conditions.

The application also uses Firebase for storing device FCM Tokens and to notify users when the conditions are good, via push notifications (If they opt into the notifications).

If a user opts into the notifications, they will receive a notification whenever the following conditions are met:

* Good conditions between the hours of 8am and 6pm.
* At least 3 consecutive hours of good conditions.