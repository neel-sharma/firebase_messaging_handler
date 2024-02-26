import 'package:shared_preferences/shared_preferences.dart';

import '../constants/index.dart';


abstract class FirebaseMessagingHandlerSharedPreferences {
  Future<void> init();

  Future<void> saveFcmToken(String token);

  String? getFcmToken();

  Future<void> removeFcmToken();
}

class FirebaseMessagingHandlerSharedPreferencesImplementation
    implements FirebaseMessagingHandlerSharedPreferences {
  late SharedPreferences prefs;

  @override
  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveFcmToken(String token) async {
    await prefs.setString(
      FirebaseMessagingHandlerConstants.fcmTokenPrefKey,
      token,
    );
  }

  @override
  String? getFcmToken() {
    return prefs.getString(FirebaseMessagingHandlerConstants.fcmTokenPrefKey);
  }

  @override
  Future<void> removeFcmToken() async {
    await prefs.remove(FirebaseMessagingHandlerConstants.fcmTokenPrefKey);
  }
}
