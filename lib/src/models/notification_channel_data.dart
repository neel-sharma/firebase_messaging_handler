import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_messaging_handler/src/enums/index.dart';
import 'package:firebase_messaging_handler/src/extensions/index.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationChannelData {
  final String id;
  final String name;
  final String? description;
  final String? groupId;
  final NotificationImportanceEnum importance;
  final bool playSound;
  final String? soundPath;
  final bool enableVibration;
  final bool enableLights;
  final Int64List? vibrationPattern;
  final Color? ledColor;
  final bool showBadge;
  final NotificationPriorityEnum priority;

  NotificationChannelData({
    required this.id,
    required this.name,
    this.description,
    this.groupId,
    this.importance = NotificationImportanceEnum.defaultImportance,
    this.playSound = true,
    this.soundPath,
    this.enableVibration = true,
    this.enableLights = false,
    this.vibrationPattern,
    this.ledColor,
    this.showBadge = true,
    this.priority = NotificationPriorityEnum.defaultPriority
  });

  AndroidNotificationChannel toAndroidNotificationChannel() {
    return AndroidNotificationChannel(
      id,
      name,
      description: description,
      groupId: groupId,
      importance: importance.getConvertedImportance,
      playSound: playSound,
      sound: soundPath != null
          ? RawResourceAndroidNotificationSound(soundPath)
          : null,
      enableVibration: enableVibration,
      vibrationPattern: vibrationPattern,
      showBadge: showBadge,
      enableLights: enableLights,
      ledColor: ledColor,
    );
  }

}


