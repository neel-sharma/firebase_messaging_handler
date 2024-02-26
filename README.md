# Firebase Messaging Handler Plugin: Streamlined Notifications, Simplified Setup

Tired of the complexities involved in handling Firebase Cloud Messaging (FCM) notifications? Our Firebase Messaging Handler plugin makes it a breeze!

**Key Benefits**

* **Unified Stream:** Get all your notification click callbacks (terminated, background, and foreground) delivered in a single, easy-to-manage stream.
* **Optimized Backend Calls:** Rest assured that the FCM update-to-backend callback triggers only once, preventing unnecessary API hits.
* **User-Friendly Permissions:** The plugin intelligently handles notification permission requests, ensuring a smooth user experience.

**Installation Steps**

1. **Add the Dependency:** Include the `firebase_messaging_handler` package in your `pubspec.yaml` file dependencies. This plugin takes care of everything, so you don't need separate `firebase_messaging` or `flutter_local_notifications` dependencies in your app.

2. Android and IOS specific changes

**Android**

Ensure the following permissions and receivers are added within the `<manifest>` section of your `android/app/src/main/AndroidManifest.xml` file:

    ```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.VIBRATE" /> 
    
    <application>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>

**IOS**
Make sure that the ios completed in developers.apple.com and APNs config is added in Firebase > Project Settings > Cloud Messaging

3.**Firebase Initialization:**
Complete the standard Firebase initialization process for your Flutter project.

4.**Get Your Sender ID:** Find your project's Sender ID within your Firebase settings.

5.**Crucial Step:**
Immediately following Firebase initialization within your app's `main` function, add this line:

   ```dart
   await FirebaseMessagingHandler.instance.checkInitial(); 
   
**Sample Functions**

* **`_initFirebaseMessagingHandler()`**

  **Purpose:** Initializes the Firebase Messaging Handler, establishes notification channels (Android-specific), and sets up a callback to handle updates to your Firebase Cloud Messaging (FCM) token.

  **Example Usage:**

   ```dart
   import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
  
   ... 

   Future<void> _initFirebaseMessagingHandler() async {
      _messagingHandler = FirebaseMessagingHandler.instance;
      clickStream = await _messagingHandler.init(
        androidChannelList: [ 
          // Your Android notification channel configurations here
        ], 
        androidNotificationIconPath: '@drawable/ic_notification',
        senderId: DefaultFirebaseOptions.android.messagingSenderId,
        updateTokenCallback: (final String fcmToken) async { 
          // Handle FCM token updates (e.g., send to backend)
          return Future.value(true); // Replace with your logic
        },
      );

      FirebaseMessagingHandler.instance.notificationClickStream.listen((notificationData) {
      // Handle all notification clicks here
      if (notificationData != null) {
      // Access notification payload: notificationData.payload
      }
      });
   }
  

  
