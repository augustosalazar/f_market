import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:f_roble_market/core/data/dummy_data.dart';

/// Bandeja local. Implementa tambien `INotificationDispatcher` porque en esta
/// fase no hay servidor que produzca las notificaciones: las produce la propia
/// app al ejecutar los casos de uso.
class LocalNotificationRepository
    implements INotificationRepository, INotificationDispatcher {
  LocalNotificationRepository(this._data);

  final DummyData _data;

  @override
  Future<List<AppNotification>> forUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_data.notifications[userId] ?? const []);
  }

  @override
  Stream<AppNotification> watch(String userId) => _data.notificationEvents
      .where((event) => event.$1 == userId)
      .map((event) => event.$2);

  @override
  Future<void> markRead(String id) async {
    for (final inbox in _data.notifications.values) {
      final index = inbox.indexWhere((n) => n.id == id);
      if (index >= 0) inbox[index] = inbox[index].copyWith(read: true);
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    final inbox = _data.notifications[userId];
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
      _data.emit(
        userId,
        AppNotification(
          id: _data.nextId('n'),
          kind: kind,
          title: title,
          body: body,
          createdAt: DateTime.now(),
          read: false,
          listingId: listingId,
          threadId: threadId,
        ),
      );
    }
  }
}
