library notification_utility;

import 'src/index.dart';
export 'src/enums/index.dart';
export 'src/models/index.dart';

/// A utility class for managing notifications, ensuring a single instance
/// through the application lifecycle using the Singleton pattern.
class FirebaseMessagingHandler {
  // Singleton instance
  static final FirebaseMessagingHandler instance =
      FirebaseMessagingHandler._internal();

  // Private constructor for internal use
  FirebaseMessagingHandler._internal();

  /// Initializes the notification utility with necessary configurations.
  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    final Future<bool> Function(String fcmToken)? updateTokenCallback,
  }) async {
    return await FirebaseMessagingUtility.instance.init(
      senderId: senderId,
      androidChannelList: androidChannelList,
      androidNotificationIconPath: androidNotificationIconPath,
      updateTokenCallback: updateTokenCallback,
    );
  }

  Future<void> checkInitial() async {
    await FirebaseMessagingUtility.instance.checkInitial();
  }

  /// Disposes of the notification utility resources.
  Future<void> dispose() async {
    await FirebaseMessagingUtility.instance.dispose();
  }

  /// Removes the stored FCM token.
  Future<void> clearToken() async {
    await FirebaseMessagingUtility.instance.clearToken();
  }

  /// Subscribes the device to the specified FCM topic.
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessagingUtility.instance.subscribeToTopic(topic);
  }

  /// Unsubscribes the device from the specified FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessagingUtility.instance.unsubscribeFromTopic(topic);
  }

  /// Unsubscribes the device from all FCM topics and clears the token.
  Future<void> unsubscribeFromAllTopics() async {
    await FirebaseMessagingUtility.instance.unsubscribeFromAllTopics();
  }
}
