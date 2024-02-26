import 'dart:developer';

import 'package:get_it/get_it.dart';

import '../index.dart';
import '../local_storage/index.dart';
import '../utilities/firebase_messaging_utility.dart';


final GetIt locator = GetIt.instance;

Future<bool> setupLocator() async {
  try {

    if (!locator.isRegistered<FirebaseMessagingHandlerSharedPreferences>()) {
      final FirebaseMessagingHandlerSharedPreferences sharedPref = FirebaseMessagingHandlerSharedPreferencesImplementation();

      await sharedPref.init();

      locator.registerLazySingleton<FirebaseMessagingHandlerSharedPreferences>(
        () => sharedPref,
      );
    }
    if (!locator.isRegistered<FirebaseMessagingHandlerPlatformUtility>()) {
      final FirebaseMessagingHandlerPlatformUtility platformUtil = FirebaseMessagingHandlerPlatformUtilityImplementation();

      platformUtil.init();

      locator.registerLazySingleton<FirebaseMessagingHandlerPlatformUtility>(
        () => platformUtil,
      );
    }
    if (!locator.isRegistered<FirebaseMessagingUtility>()) {
      locator.registerLazySingleton<FirebaseMessagingUtility>(
            () => FirebaseMessagingUtilityImplementation(
              platformUtil: locator(),
              sharedPref: locator(),
            ),
      );
    }

    return true;
  } catch (error, stack) {
    log('Locator Error: $error', name: FirebaseMessagingHandlerConstants.logName);
    log('Locator Error Stack: $stack',
        name: FirebaseMessagingHandlerConstants.logName);

    return false;
  }
}
