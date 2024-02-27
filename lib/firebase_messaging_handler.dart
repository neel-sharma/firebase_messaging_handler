library notification_utility;

import 'dart:developer';

import 'package:firebase_messaging_handler/src/locator/locator.dart';

import 'firebase_messaging_handler_platform_interface.dart';
import 'src/index.dart';

export 'src/enums/index.dart';
export 'src/models/index.dart';

/// A utility class for managing notifications, ensuring a single instance
/// through the application lifecycle using the Singleton pattern.
class FirebaseMessagingHandler {
  // Singleton instance
  static final FirebaseMessagingHandler instance =
      FirebaseMessagingHandler._internal();

  // Indicates if the locator setup has been performed
  bool _isLocatorSet = false;

  // Private constructor for internal use
  FirebaseMessagingHandler._internal();

  /// Initializes the notification utility with necessary configurations.
  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    required final Future<bool> Function(String fcmToken) updateTokenCallback,
  }) async {
    await _ensureLocatorSetup();
    return await locator<FirebaseMessagingUtility>().init(
      senderId: senderId,
      androidChannelList: androidChannelList,
      androidNotificationIconPath: androidNotificationIconPath,
      updateTokenCallback: updateTokenCallback,
    );
  }

  Future<void> checkInitial() async {
    await _ensureLocatorSetup();
    await locator<FirebaseMessagingUtility>().checkInitial();
  }

  /// Disposes of the notification utility resources.
  Future<void> dispose() async {
    if (_isLocatorSet) {
      await locator<FirebaseMessagingUtility>().dispose();
    }
  }

  /// Removes the stored FCM token.
  Future<void> clearToken() async {
    if (_isLocatorSet) {
      await locator<FirebaseMessagingUtility>().clearToken();
    }
  }

  /// Ensures the service locator is set up before any operation.
  Future<void> _ensureLocatorSetup() async {
    if (!_isLocatorSet) {
      await setupLocator();
      _isLocatorSet = true;
    } else {
      log("${FirebaseMessagingHandlerConstants.logName}: Locator already setup, skipping");
    }
  }

  Future<String?> getPlatformVersion() {
    return FirebaseMessagingHandlerPlatform.instance.getPlatformVersion();
  }
}
