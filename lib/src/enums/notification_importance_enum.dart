enum NotificationImportanceEnum {
  unspecified(-1000),
  none(0),
  min(1),
  low(2),
  defaultImportance(3),
  high(4),
  max(5);

  const NotificationImportanceEnum(this.value);

  final int value;
}
