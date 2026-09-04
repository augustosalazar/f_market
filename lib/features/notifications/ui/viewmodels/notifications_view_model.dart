import 'dart:async';

import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';

/// La bandeja del usuario actual. Se resuscribe sola cuando cambia la sesion,
/// y cancela la suscripcion al cerrarla: un stream vivo sin cancelar deja el
/// socket abierto cuando esto hable con Roble.
class NotificationsViewModel extends GetxController {
  NotificationsViewModel(this._notifications, this._session);

  final INotificationRepository _notifications;
  final SessionViewModel _session;

  final items = <AppNotification>[].obs;
  final loading = false.obs;

  StreamSubscription<AppNotification>? _subscription;

  int get unreadCount => items.where((n) => !n.read).length;

  @override
  void onInit() {
    super.onInit();
    ever(_session.user, (_) => _onSessionChanged());
    _onSessionChanged();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void _onSessionChanged() {
    _subscription?.cancel();
    _subscription = null;
    items.clear();
    final user = _session.user.value;
    if (user == null) return;

    refreshInbox();
    _subscription =
        _notifications.watch(user.userId).listen((n) => items.insert(0, n));
  }

  Future<void> refreshInbox() async {
    final user = _session.user.value;
    if (user == null) return;
    loading.value = true;
    try {
      items.assignAll(await _notifications.forUser(user.userId));
    } finally {
      loading.value = false;
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.read) return;
    await _notifications.markRead(notification.id);
    final index = items.indexWhere((n) => n.id == notification.id);
    if (index >= 0) items[index] = items[index].copyWith(read: true);
  }

  Future<void> markAllRead() async {
    final user = _session.user.value;
    if (user == null) return;
    await _notifications.markAllRead(user.userId);
    items.assignAll(items.map((n) => n.copyWith(read: true)));
  }
}
