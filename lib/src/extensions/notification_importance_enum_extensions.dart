import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../index.dart';

extension NotificationImportanceEnumExtension on NotificationImportanceEnum {
  Importance get getConvertedImportance {
    switch (this) {
      case NotificationImportanceEnum.unspecified:
        return Importance.unspecified;
      case NotificationImportanceEnum.none:
        return Importance.none;
      case NotificationImportanceEnum.min:
        return Importance.min;
      case NotificationImportanceEnum.low:
        return Importance.low;
      case NotificationImportanceEnum.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportanceEnum.high:
        return Importance.high;
      case NotificationImportanceEnum.max:
        return Importance.max;
      default:
        return Importance.defaultImportance;
    }
  }
}