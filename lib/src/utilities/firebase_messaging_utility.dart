import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/index.dart';
import '../extensions/index.dart';
import '../local_storage/index.dart';
import '../models/index.dart';
import 'firebase_messaging_app_state_utility.dart';
import 'firebase_messaging_handler_platform_utility.dart';

abstract class FirebaseMessagingUtility {
  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    required Future<bool> Function(String fcmToken) updateTokenCallback,
  });

  Future<String?> fetchFcmToken({required final String senderId});

  Future<bool> requestPermission();

  Future<void> dispose();

  Future<void> clearToken();

  Future<void> checkInitial();
}

class FirebaseMessagingUtilityImplementation
    implements FirebaseMessagingUtility {
  final FirebaseMessagingHandlerSharedPreferences sharedPref;
  final FirebaseMessagingHandlerPlatformUtility platformUtil;

  FirebaseMessagingUtilityImplementation({
    required this.sharedPref,
    required this.platformUtil,
  });

  late FirebaseMessaging firebaseMessagingInstance;
  final Set<int> openedNotifications = {};
  final Set<int> foregroundShownNotifications = {};
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Function? onClickCallback;
  StreamController<NotificationData?>? clickStreamController;
  Stream<NotificationData?>? clickStream;
  RemoteMessage? initialMessage;

  @override
  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    required Future<bool> Function(String fcmToken) updateTokenCallback,
  }) async {
    firebaseMessagingInstance = FirebaseMessaging.instance;
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final bool permissionsGranted = await requestPermission();
    if (permissionsGranted) {
      final String? savedFcmToken = await sharedPref.getFcmToken();
      if (savedFcmToken == null) {
        final String? fcmToken = await fetchFcmToken(senderId: senderId);
        if (fcmToken != null) {
          final bool updateSuccessful = await updateTokenCallback(fcmToken);
          if (updateSuccessful) {
            sharedPref.saveFcmToken(fcmToken);
          }
        } else {
          log('Error fetching FCM Token!',
              name: FirebaseMessagingHandlerConstants.logName);
        }
      }
      await initializeLocalNotifications(
        androidChannelList: androidChannelList,
        androidNotificationIconPath: androidNotificationIconPath,
      );
      FirebaseMessagingAppStateUtility.instance.initialize();
      listenToForegroundNotifications(
        androidChannelList: androidChannelList,
        androidNotificationIconPath: androidNotificationIconPath,
      );
      await handleBackgroundTerminatedNotifications();

      return getNotificationClickStream();
    }
    return null;
  }

  @override
  Future<void> checkInitial() async {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  Future<String?> fetchFcmToken({required final String senderId}) async {
    try {
      final String? fcmToken =
          await firebaseMessagingInstance.getToken(vapidKey: senderId);

      return fcmToken;
    } catch (error, stack) {
      log('FCM Error: $error', name: FirebaseMessagingHandlerConstants.logName);
      log('FCM Error Stack: $stack',
          name: FirebaseMessagingHandlerConstants.logName);

      return null;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final NotificationSettings notificationSettings =
          await firebaseMessagingInstance.requestPermission();

      return notificationSettings.authorizationStatus ==
          AuthorizationStatus.authorized;
    } catch (error, stack) {
      log('FCM asking for notification permission.\n$error',
          name: FirebaseMessagingHandlerConstants.logName);
      log('FCM Error Stack: $stack',
          name: FirebaseMessagingHandlerConstants.logName);

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
      log('Init Local Notifications Error: $error',
          name: FirebaseMessagingHandlerConstants.logName);
      log('Error Stack: $stack',
          name: FirebaseMessagingHandlerConstants.logName);
    }
  }

  void listenToForegroundNotifications({
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) {
    if (platformUtil.isAndroid) {
      FirebaseMessaging.onMessage.listen((final RemoteMessage message) async {
        final RemoteNotification? notification = message.notification;
        // Ensure high priority if it's a foreground notification
        if (notification != null &&
            !foregroundShownNotifications.contains(notification.hashCode)) {
          foregroundShownNotifications.add(notification.hashCode);

          // Find the appropriate channel (ensure priority is high)
          AndroidNotificationChannel? selectedChannel;
          for (final NotificationChannelData channelData
              in androidChannelList) {
            if (channelData.id == message.notification!.android!.channelId) {
              // Adapt channel properties for foreground notification
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
      });
    }
  }

  Future<void> handleBackgroundTerminatedNotifications() async {
    if (initialMessage != null) {
      getNotificationClickStream();
      processNotification(initialMessage!);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(processNotification);
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
    clickStreamController?.add(
      NotificationData(
        payload: payload,
      ),
    );
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
          log('The Channel ID from the notification is not matching the any of the Channel IDs set in app.',
              name: FirebaseMessagingHandlerConstants.logName);
          log('Please make sure you are sending the Channel ID which you are setting in androidChannelList',
              name: FirebaseMessagingHandlerConstants.logName);
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
        log('Show Local Notification for Android Error: No Channel ID found',
            name: FirebaseMessagingHandlerConstants.logName);
      }
    } catch (error, stack) {
      log('Init Local Notifications Error: $error',
          name: FirebaseMessagingHandlerConstants.logName);
      log('Error Stack: $stack',
          name: FirebaseMessagingHandlerConstants.logName);
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
      clickStreamController = StreamController<NotificationData?>();
      clickStream = clickStreamController!.stream;
    }

    return clickStream!;
  }

  @override
  Future<void> dispose() async {
    openedNotifications.clear();
    foregroundShownNotifications.clear();
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<void> clearToken() async {
    await sharedPref.removeFcmToken();
  }
}
