import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/index.dart';
import '../extensions/index.dart';
import '../models/index.dart';

class FirebaseMessagingUtility {
  static FirebaseMessagingUtility? _instance;

  /// Singleton instance of the FirebaseMessagingUtility.
  static FirebaseMessagingUtility get instance {
    _instance ??= FirebaseMessagingUtility._internal();
    return _instance!;
  }

  /// Private constructor for singleton pattern.
  FirebaseMessagingUtility._internal();

  /// Instance of Firebase Messaging.
  late FirebaseMessaging firebaseMessagingInstance;

  /// Stores IDs of notifications opened during the session.
  final Set<int> openedNotifications = {};

  /// Stores IDs of notifications shown in the foreground.
  final Set<int> foregroundShownNotifications = {};

  /// Stores session-specific notification IDs.
  static Set<int> sessionNotifications = {};

  /// Instance of Flutter Local Notifications Plugin.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  /// Callback for handling notification clicks.
  Function? onClickCallback;

  /// Stream controller for notification click events.
  StreamController<NotificationData?>? clickStreamController;

  /// Stream for listening to notification click events.
  Stream<NotificationData?>? clickStream;

  /// Stores the initial notification message if app was opened via notification.
  RemoteMessage? initialMessage;

  /// Shared Preferences instance for storing persistent data.
  SharedPreferences? sharedPref;

  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    Future<bool> Function(String fcmToken)? updateTokenCallback,
  }) async {
    firebaseMessagingInstance = FirebaseMessaging.instance;
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final bool permissionsGranted = await requestPermission();
    if (permissionsGranted) {
      final String? savedFcmToken = await getFcmToken();
      if (savedFcmToken == null && updateTokenCallback != null) {
        final String? fcmToken = await fetchFcmToken(senderId: senderId);

        if (fcmToken != null) {
          final bool updateSuccessful = await updateTokenCallback(fcmToken);
          if (updateSuccessful) {
            await saveFcmToken(fcmToken);
          }
        } else {
          _logMessage(
            'Error fetching FCM Token!',
          );
        }
      }
      await initializeLocalNotifications(
        androidChannelList: androidChannelList,
        androidNotificationIconPath: androidNotificationIconPath,
      );
      listenToForegroundNotifications(
        androidChannelList: androidChannelList,
        androidNotificationIconPath: androidNotificationIconPath,
      );
      await handleBackgroundNotifications();

      if (initialMessage?.data != null) {
        ///Handles terminated notification and instantly fires an event on subscribing.
        final payload = initialMessage!.data;
        initialMessage = null;
        return getNotificationClickStream()
            .startWith(NotificationData(payload: payload));
      } else {
        return getNotificationClickStream();
      }
    }
    return null;
  }

  Future<void> checkInitial() async {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    ///Alternative approach to get the payload from previous session cache
    // if (initialMessage != null) {
    //   final restoredMessages = await restoreSessionNotifications();
    //   final int messageHash = initialMessage!.messageId.hashCode;
    //   final matchingMessage = restoredMessages.firstWhere(
    //     (message) {
    //       return message.messageId.hashCode == messageHash;
    //     },
    //     orElse: () => initialMessage!,
    //   );
    //
    //   if (matchingMessage != initialMessage) {
    //     initialMessage = matchingMessage;
    //   }
    // }
    //await clearSessionNotifications();
  }

  Future<String?> fetchFcmToken({required final String senderId}) async {
    try {
      final String? fcmToken =
          await firebaseMessagingInstance.getToken(vapidKey: senderId);
      return fcmToken;
    } catch (error, stack) {
      _logMessage(
        'FCM Error: $error',
      );
      _logMessage(
        'FCM Error Stack: $stack',
      );

      return null;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final NotificationSettings notificationSettings =
          await firebaseMessagingInstance.requestPermission();

      return notificationSettings.authorizationStatus ==
          AuthorizationStatus.authorized;
    } catch (error, stack) {
      _logMessage(
        'FCM asking for notification permission.\n$error',
      );
      _logMessage(
        'FCM Error Stack: $stack',
      );

      return false;
    }
  }

  Future<void> initializeLocalNotifications({
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) async {
    try {
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings(androidNotificationIconPath),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
        ),
      );

      final bool? isInitialized =
          await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onSelectNotification,
      );
      if (isInitialized != null && isInitialized) {
        for (final NotificationChannelData channel in androidChannelList) {
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(
                  channel.toAndroidNotificationChannel());
        }

        await firebaseMessagingInstance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (error, stack) {
      _logMessage(
        'Init Local Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  void listenToForegroundNotifications({
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        FirebaseMessaging.onMessage.listen(
          (final RemoteMessage message) async {
            final RemoteNotification? notification = message.notification;

            await saveNotification(message);

            if (notification != null &&
                !foregroundShownNotifications.contains(notification.hashCode)) {
              foregroundShownNotifications.add(notification.hashCode);

              AndroidNotificationChannel? selectedChannel;
              for (final NotificationChannelData channelData
                  in androidChannelList) {
                if (channelData.id ==
                    message.notification!.android!.channelId) {
                  selectedChannel = channelData.toAndroidNotificationChannel();
                  selectedChannel.copyWith(
                    importance: Importance.max,
                  );

                  break;
                }
              }

              await _showLocalNotification(
                message: message,
                androidChannelList: androidChannelList,
                androidNotificationIconPath: androidNotificationIconPath,
              );
            }
          },
        );
      } else {
        FirebaseMessaging.onMessage.listen(
          (final RemoteMessage message) async {
            await saveNotification(message);
          },
        );
      }
    }
  }

  Future<void> handleBackgroundNotifications() async {
    if (initialMessage != null) {
      getNotificationClickStream();
      processNotification(
        initialMessage!,
        isFromTerminated: true,
      );
    }

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(processNotification);
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundMessage(RemoteMessage message) async {
    await saveNotification(message);
  }

  void processNotification(final RemoteMessage message,
      {bool isFromTerminated = false}) {
    if (!openedNotifications.contains(message.messageId.hashCode)) {
      openedNotifications.add(message.messageId.hashCode);
      addNotificationClickStreamEvent(
        message.data,
        isFromTerminated: isFromTerminated,
      );
    }
  }

  void addNotificationClickStreamEvent(final Map<String, dynamic> payload,
      {bool isFromTerminated = false}) {
    if (isFromTerminated) {
      clickStream?.startWith(
        NotificationData(
          payload: payload,
        ),
      );
    } else {
      clickStreamController?.add(
        NotificationData(
          payload: payload,
        ),
      );
    }
  }

  Future<void> _showLocalNotification({
    required final RemoteMessage message,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) async {
    try {
      if (message.notification?.android?.channelId != null) {
        AndroidNotificationChannel? selectedChannel;
        Priority? priority;
        for (final NotificationChannelData channelData in androidChannelList) {
          if (channelData.id == message.notification!.android!.channelId) {
            selectedChannel = channelData.toAndroidNotificationChannel();
            priority = channelData.priority.getConvertedPriority;
          }
        }

        if (selectedChannel == null) {
          _logMessage(
            'The Channel ID from the notification is not matching the any of the Channel IDs set in app.',
          );
          _logMessage(
            'Please make sure you are sending the Channel ID which you are setting in androidChannelList',
          );
        }

        await flutterLocalNotificationsPlugin.show(
          message.notification.hashCode,
          message.notification?.title,
          message.notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              message.notification!.android!.channelId!,
              selectedChannel?.name ??
                  message.notification!.android!.channelId!,
              importance:
                  selectedChannel?.importance ?? Importance.defaultImportance,
              priority: priority ?? Priority.defaultPriority,
              icon: androidNotificationIconPath,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      } else {
        _logMessage(
          'Show Local Notification for Android Error: No Channel ID found',
        );
      }
    } catch (error, stack) {
      _logMessage(
        'Init Local Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<void> onSelectNotification(
    final NotificationResponse response,
  ) async {
    //Note: The Remote Message hash code is stored in 'response.id'
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      if (response.id != null && !openedNotifications.contains(response.id)) {
        openedNotifications.add(response.id!);
        addNotificationClickStreamEvent(
            jsonDecode(response.payload.toString()));
      }
    }
  }

  Stream<NotificationData?> getNotificationClickStream() {
    if (clickStreamController == null || clickStream == null) {
      clickStreamController = StreamController<NotificationData?>.broadcast();
      clickStream = clickStreamController!.stream;
    }

    return clickStream!;
  }

  Future<void> dispose() async {
    openedNotifications.clear();
    foregroundShownNotifications.clear();
    await flutterLocalNotificationsPlugin.cancelAll();
    await clickStreamController?.close();
  }

  Future<void> clearToken() async {
    sharedPref ??= await SharedPreferences.getInstance();
    await removeFcmToken();
  }

  Future<void> saveFcmToken(String token) async {
    sharedPref ??= await SharedPreferences.getInstance();
    await sharedPref!.setString(
      FirebaseMessagingHandlerConstants.fcmTokenPrefKey,
      token,
    );
  }

  Future<String?> getFcmToken() async {
    sharedPref ??= await SharedPreferences.getInstance();
    return Future.value(sharedPref!
        .getString(FirebaseMessagingHandlerConstants.fcmTokenPrefKey));
  }

  Future<void> removeFcmToken() async {
    sharedPref ??= await SharedPreferences.getInstance();
    await sharedPref!.remove(FirebaseMessagingHandlerConstants.fcmTokenPrefKey);
  }

  static Future<void> saveNotification(RemoteMessage message) async {
    ///Alternative approach to get the payload from previous session cache
    // final prefs = await SharedPreferences.getInstance();
    // final String? storedData =
    //     prefs.getString(FirebaseMessagingHandlerConstants.sessionPrefKey);
    //
    // // Parse existing stored messages
    // final List<Map<String, dynamic>> currentMessages = storedData != null
    //     ? List<Map<String, dynamic>>.from(jsonDecode(storedData))
    //     : [];
    //
    // // Check if the message is already saved (using hash code)
    // final int messageHash = message.messageId.hashCode;
    // final bool isDuplicate = currentMessages.any((msg) {
    //   return msg['messageId']?.hashCode == messageHash;
    // });
    //
    // if (!isDuplicate) {
    //   // Add the new message
    //   currentMessages.add(message.toMap());
    //
    //   // Save updated list to SharedPreferences
    //   prefs.setString(
    //     FirebaseMessagingHandlerConstants.sessionPrefKey,
    //     jsonEncode(currentMessages),
    //   );
    //
    //   // Also track the message hash in session memory (optional)
    //   sessionNotifications.add(messageHash);
    // }
  }

  Future<List<RemoteMessage>> restoreSessionNotifications() async {
    ///Alternative approach to get the payload from previous session cache
    // final prefs = await SharedPreferences.getInstance();
    // final storedData =
    //     prefs.getString(FirebaseMessagingHandlerConstants.sessionPrefKey);
    //
    // if (storedData != null) {
    //   // Deserialize the stored list of RemoteMessage objects
    //   final List<dynamic> jsonList = jsonDecode(storedData);
    //   final List<RemoteMessage> restoredMessages = jsonList
    //       .cast<Map<String, dynamic>>()
    //       .map((data) => RemoteMessage.fromMap(data))
    //       .toList();
    //
    //   // Add to sessionNotifications
    //   for (final RemoteMessage message in restoredMessages) {
    //     sessionNotifications.add(message.messageId.hashCode);
    //   }
    //
    //   _logMessage(
    //       'Restored ${restoredMessages.length} notifications from session.');
    //   return restoredMessages;
    // }

    return [];
  }

  Future<void> clearSessionNotifications() async {
    ///Alternative approach to get the payload from previous session cache
    // sessionNotifications.clear();
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('session_notifications');
    // _logMessage('Session notifications cleared.');
  }

  void _logMessage(String message) {
    log(message, name: FirebaseMessagingHandlerConstants.logName);
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await firebaseMessagingInstance.subscribeToTopic(topic);
      _logMessage('Subscribed to topic: $topic');
    } catch (error, stack) {
      _logMessage('Error subscribing to topic $topic: $error');
      _logMessage('Stack trace: $stack');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await firebaseMessagingInstance.unsubscribeFromTopic(topic);
      _logMessage('Unsubscribed from topic: $topic');
    } catch (error, stack) {
      _logMessage('Error unsubscribing from topic $topic: $error');
      _logMessage('Stack trace: $stack');
    }
  }

  /// Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics() async {
    try {
      await firebaseMessagingInstance.deleteToken();
      _logMessage('Unsubscribed from all topics by deleting FCM token.');
    } catch (error, stack) {
      _logMessage('Error unsubscribing from all topics: $error');
      _logMessage('Stack trace: $stack');
    }
  }
}
