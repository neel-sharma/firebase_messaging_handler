# Firebase Messaging Handler Plugin: Streamlined Notifications, Simplified Setup

Tired of the complexities involved in handling Firebase Cloud Messaging (FCM) notifications? Our Firebase Messaging Handler plugin makes it a breeze!

**Key Benefits**

* **Unified Stream:** Get all your notification click callbacks (terminated, background, and foreground) delivered in a single, easy-to-manage stream.
* **Optimized Backend Calls:** Rest assured that the FCM update-to-backend callback triggers only once, preventing unnecessary API hits.
* **User-Friendly Permissions:** The plugin intelligently handles notification permission requests, ensuring a smooth user experience.

**Installation Steps**

1. **Add the Dependency:** Include the `firebase_messaging_handler` package in your `pubspec.yaml` file dependencies. This plugin takes care of everything, so you don't need separate `firebase_messaging` or `flutter_local_notifications` dependencies in your app.

2. **Firebase Initialization:** Complete the standard Firebase initialization process for your Flutter project.

3. **Get Your Sender ID:** Find your project's Sender ID within your Firebase settings.

4. **Crucial Step:** Immediately following Firebase initialization within your app's `main` function, add this line:

   ```dart
   await FirebaseMessagingHandler.instance.checkInitial(); 
