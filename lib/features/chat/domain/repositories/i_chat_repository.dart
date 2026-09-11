import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';

/// Chats privados entre comprador y vendedor.
abstract class IChatRepository {
  Future<List<ChatThread>> threadsOf(String userId);

  Future<ChatThread?> threadById(String threadId);

  /// Los chats abiertos sobre una publicacion. Es de donde salen los
  /// candidatos a comprador cuando el vendedor la cierra: quien pregunto por
  /// privado es quien pudo haberla comprado.
  Future<List<ChatThread>> threadsOfListing(String listingId);

  /// Devuelve el chat de esa publicacion con ese comprador, creandolo si aun
  /// no existe. Es el punto de entrada del boton «Chat privado».
  Future<ChatThread> openThread({
    required String listingId,
    required String buyerId,
  });

  Future<List<ChatMessage>> messagesOf(String threadId);

  /// Los mensajes que lleguen de ahora en adelante. No reenvia los que ya
  /// estaban: la pantalla lee primero con `messagesOf` y pega encima lo que
  /// vaya llegando. Hay que cancelar la suscripcion al salir.
  Stream<ChatMessage> watchMessages(String threadId);

  Future<ChatMessage> send({
    required String threadId,
    required String senderId,
    required String text,
  });

  /// Silencia o reactiva las notificaciones del hilo.
  Future<ChatThread> setMuted({required String threadId, required bool muted});

  Future<void> markRead(String threadId);
}
