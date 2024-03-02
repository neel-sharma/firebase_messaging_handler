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

 *For In-App Messaging just add firebase_in_app_messaging in your yaml.
 And enable multidex support to your `build.gradle`(android/app/build.gradle):*

    android {
    defaultConfig {
        ...
        multiDexEnabled true
        ...
    }
    ...
    dependencies {
    ...
    implementation "androidx.multidex:multidex:2.0.1"
    ...
    }

**IOS**
Make sure that the ios completed in developers.apple.com and APNs config is added in Firebase > Project Settings > Cloud Messaging

3.**Firebase Initialization:**
Complete the standard Firebase initialization process for your Flutter project.

4.**Get Your Sender ID:** Find your project's Sender ID within your Firebase settings.

5.**Crucial Step:**
Immediately following Firebase initialization within your app's `main` function, add this line:

   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   await FirebaseMessagingHandler.instance.checkInitial(); 

   
**Sample Functions**

  **Purpose:** Initializes the Firebase Messaging Handler, establishes notification channels (Android-specific), and sets up a callback to handle updates to your Firebase Cloud Messaging (FCM) token.

  **Example Usage: (anywhere in the application after Firebase Initialization)**

   import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';

    Future<void> _initFirebaseMessagingHandler() async {
    _messagingHandler = FirebaseMessagingHandler.instance;
    Stream<NotificationData?>? clickStream = await _messagingHandler.init(
      androidChannelList: [
        NotificationChannelData(
          id: 'android_notification_channel_id',
          name: 'name can be anything',
          importance: NotificationImportanceEnum.max,
          priority: NotificationPriorityEnum.high,
        ),
      ],
      androidNotificationIconPath: '@drawable/ic_notification',
      senderId: DefaultFirebaseOptions.android.messagingSenderId,
      updateTokenCallback: (final String fcmToken) async {
        log('FCM Token: $fcmToken');
        setState(() {
          _showClearButton = true;
        });
        //Use print for release mode FCM Debugging
        //print('FCM Token: $fcmToken');

        //Returning true lets the utility know that the token has been saved by the backend.
        //And so this function should not be called till the token has been cleared with the removeToken()
        //Note: Re-installing or clearing data will also recall this function.
        return Future.value(true);
      },
    );

    if (clickStream != null) {
      clickStream.listen((NotificationData? data) {
        if (data != null) {
          setState(() {
            _currentPayload =
                (data.payload.isNotEmpty ? data.payload : '').toString();
          });
        }
      });
    }
    }
  
  

  
