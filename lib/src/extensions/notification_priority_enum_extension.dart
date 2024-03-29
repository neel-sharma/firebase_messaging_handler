import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

extension NotificationPriorityEnumExtension on NotificationPriorityEnum {
  Priority get getConvertedPriority {
    switch (this) {
      case NotificationPriorityEnum.min:
        return Priority.min;
      case NotificationPriorityEnum.low:
        return Priority.low;
      case NotificationPriorityEnum.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriorityEnum.high:
        return Priority.high;
      case NotificationPriorityEnum.max:
        return Priority.max;
      default:
        return Priority.defaultPriority;
    }
  }
}
