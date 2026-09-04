/// Un chat privado entre un comprador y el vendedor, sobre una publicacion.
///
/// `muted` es lo que el requisito llama «bloquear el chat»: el hilo sigue
/// funcionando, pero deja de emitir notificaciones para este usuario.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingCover,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.muted,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingCover;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool muted;

  /// El nombre de la contraparte, visto desde `userId`.
  String otherName(String userId) => userId == sellerId ? buyerName : sellerName;

  ChatThread copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? muted,
  }) => ChatThread(
    id: id,
    listingId: listingId,
    listingTitle: listingTitle,
    listingCover: listingCover,
    buyerId: buyerId,
    buyerName: buyerName,
    sellerId: sellerId,
    sellerName: sellerName,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    muted: muted ?? this.muted,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
}
