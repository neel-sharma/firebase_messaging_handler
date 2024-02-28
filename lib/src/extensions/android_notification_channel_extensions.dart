import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

extension AndroidNotificationChannelCopyWith on AndroidNotificationChannel {
  AndroidNotificationChannel copyWith({
    String? id,
    String? name,
    String? description,
    String? groupId,
    Importance? importance,
    bool? playSound,
    AndroidNotificationSound? sound,
    bool? enableVibration,
    Int64List? vibrationPattern,
    bool? showBadge,
    bool? enableLights,
    Color? ledColor,
  }) {
    return AndroidNotificationChannel(
      id ?? this.id,
      name ?? this.name,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      importance: importance ?? this.importance,
      playSound: playSound ?? this.playSound,
      sound: sound ?? this.sound,
      enableVibration: enableVibration ?? this.enableVibration,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      showBadge: showBadge ?? this.showBadge,
      enableLights: enableLights ?? this.enableLights,
      ledColor: ledColor ?? this.ledColor,
    );
  }
}
