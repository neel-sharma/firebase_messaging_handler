import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'firebase_messaging_handler_platform_interface.dart';

/// An implementation of [FirebaseMessagingHandlerPlatform] that uses method channels.
class MethodChannelFirebaseMessagingHandler extends FirebaseMessagingHandlerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('firebase_messaging_handler');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
