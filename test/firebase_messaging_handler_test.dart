import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler_platform_interface.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFirebaseMessagingHandlerPlatform
    with MockPlatformInterfaceMixin
    implements FirebaseMessagingHandlerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FirebaseMessagingHandlerPlatform initialPlatform = FirebaseMessagingHandlerPlatform.instance;

  test('$MethodChannelFirebaseMessagingHandler is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFirebaseMessagingHandler>());
  });

  test('getPlatformVersion', () async {
    FirebaseMessagingHandler firebaseMessagingHandlerPlugin = FirebaseMessagingHandler.instance;
    MockFirebaseMessagingHandlerPlatform fakePlatform = MockFirebaseMessagingHandlerPlatform();
    FirebaseMessagingHandlerPlatform.instance = fakePlatform;

    expect(await firebaseMessagingHandlerPlugin.getPlatformVersion(), '42');
  });
}
