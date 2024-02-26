import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:flutter/widgets.dart';

class FirebaseMessagingAppStateUtility {
  // Private constructor to enforce singleton pattern
  FirebaseMessagingAppStateUtility._();

  // Static instance
  static final FirebaseMessagingAppStateUtility _instance =
      FirebaseMessagingAppStateUtility._();

  // Factory getter to access the singleton instance
  static FirebaseMessagingAppStateUtility get instance => _instance;

  // Current state of the app
  FirebaseMessagingHandlerAppStateEnum _currentState =
      FirebaseMessagingHandlerAppStateEnum.background;

  // Logic to update the state (using WidgetsBindingObserver)
  void initialize() {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(_updateState));
  }

  void _updateState(AppLifecycleState state) {
    _currentState = state == AppLifecycleState.hidden
        ? FirebaseMessagingHandlerAppStateEnum.background
        : FirebaseMessagingHandlerAppStateEnum.foreground;
  }

  // Method to get the current state
  FirebaseMessagingHandlerAppStateEnum getCurrentState() {
    return _currentState;
  }

  bool get isForeground =>
      _currentState == FirebaseMessagingHandlerAppStateEnum.foreground;
}

// Helper class to listen to lifecycle changes
class _LifecycleObserver extends WidgetsBindingObserver {
  final Function(AppLifecycleState state) onStateChanged;

  _LifecycleObserver(this.onStateChanged);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    onStateChanged(state);
  }
}
