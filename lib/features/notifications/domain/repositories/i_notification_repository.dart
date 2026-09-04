import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';

/// La bandeja de notificaciones del usuario.
///
/// `watch` es el hueco por donde entrara el tiempo real de Roble; la fuente
/// local lo alimenta con las notificaciones que producen las propias acciones
/// de la app, para poder probar la pantalla sin servidor.
abstract class INotificationRepository {
  Future<List<AppNotification>> forUser(String userId);

  Stream<AppNotification> watch(String userId);

  Future<void> markRead(String id);

  Future<void> markAllRead(String userId);
}

/// Quien produce las notificaciones.
///
/// Se separa de la bandeja porque en produccion el productor es el servidor:
/// los casos de uso llaman a `dispatch` y la implementacion de Roble no hara
/// nada, porque el backend ya emitio la notificacion. En esta fase, la fuente
/// local lo implementa para que la bandeja se llene con lo que hace la app.
abstract class INotificationDispatcher {
  Future<void> dispatch({
    required List<String> userIds,
    required NotificationKind kind,
    required String title,
    required String body,
    String? listingId,
    String? threadId,
  });
}
