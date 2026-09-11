import 'dart:async';

import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';

/// La bandeja mientras las notificaciones no esten en Roble.
///
/// Vive en memoria y se pierde al cerrar la app: los avisos que produce esta
/// sesion se ven, los que produzca otro dispositivo no. Es a proposito —las
/// notificaciones son una fase aparte— y por eso implementa tambien
/// `INotificationDispatcher`: hoy quien las produce es la propia app. Cuando
/// las produzca el servidor, `dispatch` se queda sin hacer nada.
class InMemoryNotificationRepository
    implements INotificationRepository, INotificationDispatcher {
  final _inboxes = <String, List<AppNotification>>{};
  final _events = StreamController<(String, AppNotification)>.broadcast();

  var _counter = 0;

  @override
  Future<List<AppNotification>> forUser(String userId) async =>
      List.of(_inboxes[userId] ?? const []);

  @override
  Stream<AppNotification> watch(String userId) => _events.stream
      .where((event) => event.$1 == userId)
      .map((event) => event.$2);

  @override
  Future<void> markRead(String id) async {
    for (final inbox in _inboxes.values) {
      final index = inbox.indexWhere((n) => n.id == id);
      if (index >= 0) inbox[index] = inbox[index].copyWith(read: true);
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    final inbox = _inboxes[userId];
    if (inbox == null) return;
    for (var i = 0; i < inbox.length; i++) {
      inbox[i] = inbox[i].copyWith(read: true);
    }
  }

  @override
  Future<void> dispatch({
    required List<String> userIds,
    required NotificationKind kind,
    required String title,
    required String body,
    String? listingId,
    String? threadId,
  }) async {
    for (final userId in userIds) {
      final notification = AppNotification(
        id: 'n_${++_counter}',
        kind: kind,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        read: false,
        listingId: listingId,
        threadId: threadId,
      );
      _inboxes.putIfAbsent(userId, () => []).insert(0, notification);
      _events.add((userId, notification));
    }
  }
}
