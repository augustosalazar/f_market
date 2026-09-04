/// El motivo por el que se genero una notificacion.
///
/// Cada valor corresponde a uno de los disparadores del requisito: preguntas y
/// respuestas y cambios de estado para quien sigue la publicacion, preguntas
/// nuevas para el vendedor, y mensajes para los chats no silenciados.
enum NotificationKind {
  question('Pregunta nueva'),
  answer('Respuesta del vendedor'),
  statusChange('Cambio de estado'),
  chatMessage('Mensaje privado');

  const NotificationKind(this.label);
  final String label;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.listingId,
    this.threadId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? listingId;
  final String? threadId;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    listingId: listingId,
    threadId: threadId,
  );
}
