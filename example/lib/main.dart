import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessagingHandler.instance.checkInitial();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notification Utility Example',
      home: NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late FirebaseMessagingHandler _messagingHandler;
  String? _currentPayload;

  @override
  void initState() {
    _initFirebaseMessagingHandler();
    super.initState();
  }

  @override
  Future<void> dispose() async {
    await _disposeFirebaseMessagingHandler();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handler Example'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Current Payload: \n$_currentPayload',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
        child: const Text(
          'Clear',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          setState(() {
            _currentPayload = null;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _initFirebaseMessagingHandler() async {
    _messagingHandler = FirebaseMessagingHandler.instance;
    Stream<NotificationData?>? clickStream = await _messagingHandler.init(
      androidChannelList: [
        NotificationChannelData(
          id: 'android_notification_channel_id',
          name: 'name can be anything',
          importance: NotificationImportanceEnum.max,
          priority: NotificationPriorityEnum.high,
        )
        //NotificationChannelData(),
      ],
      androidNotificationIconPath: '@drawable/ic_notification',
      senderId: DefaultFirebaseOptions.android.messagingSenderId,
      updateTokenCallback: (final String fcmToken) async {
        print('FCM Token: $fcmToken');

        //Returning true lets the utility know that the token has been saved by the backend.
        //And so this function should not be called till the token has been cleared with the removeToken()
        //Note: Re-installing or clearing data will also recall this function.
        return Future.value(false);
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

  Future<void> _disposeFirebaseMessagingHandler() async {
    _messagingHandler.dispose();
  }
}
