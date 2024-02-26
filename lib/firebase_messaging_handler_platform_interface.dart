import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'firebase_messaging_handler_method_channel.dart';

abstract class FirebaseMessagingHandlerPlatform extends PlatformInterface {
  /// Constructs a FirebaseMessagingHandlerPlatform.
  FirebaseMessagingHandlerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FirebaseMessagingHandlerPlatform _instance = MethodChannelFirebaseMessagingHandler();

  /// The default instance of [FirebaseMessagingHandlerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFirebaseMessagingHandler].
  static FirebaseMessagingHandlerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FirebaseMessagingHandlerPlatform] when
  /// they register themselves.
  static set instance(FirebaseMessagingHandlerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
