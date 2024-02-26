enum NotificationPriorityEnum {
  min(-2),
  low(-1),
  defaultPriority(0),
  high(1),
  max(2);

  const  NotificationPriorityEnum(this.value);

  final int value;
}
