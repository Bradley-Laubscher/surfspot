# 🏄‍♂️ SurfSpot

**SurfSpot** is a surf forecast application built with **Dart** and **Flutter**, designed to help surfers find the best times to hit the waves. The app pulls real-time surf conditions and forecasts using the **Open-Meteo API**, and optionally notifies users when conditions are optimal via **Firebase Cloud Messaging** (FCM).

🌐 **Live Site:** [surfspot.netlify.app](https://surfspot.netlify.app/)

---

## 🌊 Features

- **Live Surf Forecasts**  
  Uses [Open-Meteo](https://open-meteo.com/) APIs to retrieve current surf conditions and forecasts for multiple spots.

- **Spot Discovery**  
  Navigate a carousel of surf locations, each with visuals and coordinates.

- **Smart Notifications (FCM)**  
  Users who opt in will receive push notifications when ideal surf conditions are detected:
    - Conditions are good **between 8 AM and 6 PM**.
    - Forecast predicts **at least 3 consecutive hours** of good surf.

  ⚠️ **Note:** Notifications currently work **only when the application is launched on mobile devices** (Android/iOS).

- **Cross-Platform**  
  Built with Flutter and compatible with **Web, Android, and Windows**.

- **Interactive Surf Map**  
  Displays surf spots on a dynamic Google Map (Web and Windows support).

---

## 🚀 Tech Stack

- **Frontend:** Flutter (Dart)
- **Weather Data:** Open-Meteo API
- **Push Notifications:** Firebase Cloud Messaging
- **State Management:** Provider
- **Backend:** Firebase Firestore (for storing device tokens)
- **Map Integration:** Google Maps (Windows + Web)

---