import 'dart:async';

extension NotificationStreamExtensions<T> on Stream<T> {
  Stream<T> startWith(final T initialValue) {
    final StreamController<T> controller = StreamController<T>();
    controller.add(initialValue);
    listen(
      controller.add,
      onDone: controller.close,
      onError: controller.addError,
      cancelOnError: true,
    );

    return controller.stream;
  }
}
