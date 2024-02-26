import 'package:flutter/foundation.dart';
import 'package:platform/platform.dart';

abstract class FirebaseMessagingHandlerPlatformUtility {
  void init();

  bool get isWeb;

  bool get isAndroid;

  bool get isIos;
}

class FirebaseMessagingHandlerPlatformUtilityImplementation
    implements FirebaseMessagingHandlerPlatformUtility {
  late Platform platform;

  @override
  void init() {
    platform = const LocalPlatform();
  }

  @override
  bool get isWeb => kIsWeb;

  @override
  bool get isAndroid {
    return !isWeb && platform.isAndroid;
  }

  @override
  bool get isIos {
    return !isWeb && platform.isIOS;
  }
}
