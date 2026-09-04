import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';

/// Chats privados entre comprador y vendedor.
abstract class IChatRepository {
  Future<List<ChatThread>> threadsOf(String userId);

  Future<ChatThread?> threadById(String threadId);

  /// Devuelve el chat de esa publicacion con ese comprador, creandolo si aun
  /// no existe. Es el punto de entrada del boton «Chat privado».
  Future<ChatThread> openThread({
    required String listingId,
    required String buyerId,
  });

  Future<List<ChatMessage>> messagesOf(String threadId);

  Future<ChatMessage> send({
    required String threadId,
    required String senderId,
    required String text,
  });

  /// Silencia o reactiva las notificaciones del hilo.
  Future<ChatThread> setMuted({required String threadId, required bool muted});

  Future<void> markRead(String threadId);
}
