import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/core/data/dummy_data.dart';

class LocalChatRepository implements IChatRepository {
  LocalChatRepository(this._data);

  final DummyData _data;

  @override
  Future<List<ChatThread>> threadsOf(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final result = _data.threads
        .where((t) => t.buyerId == userId || t.sellerId == userId)
        .toList();
    result.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return result;
  }

  @override
  Future<ChatThread?> threadById(String threadId) async =>
      _data.threads.where((t) => t.id == threadId).firstOrNull;

  @override
  Future<ChatThread> openThread({
    required String listingId,
    required String buyerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final existing = _data.threads
        .where((t) => t.listingId == listingId && t.buyerId == buyerId)
        .firstOrNull;
    if (existing != null) return existing;

    final listing = _data.listings.firstWhere((l) => l.id == listingId);
    final buyer = _data.users.firstWhere((u) => u.userId == buyerId);
    final thread = ChatThread(
      id: _data.nextId('t'),
      listingId: listing.id,
      listingTitle: listing.title,
      listingCover: listing.cover,
      buyerId: buyer.userId,
      buyerName: buyer.name,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
      muted: false,
    );
    _data.threads.add(thread);
    _data.messages[thread.id] = [];
    return thread;
  }

  @override
  Future<List<ChatMessage>> messagesOf(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_data.messages[threadId] ?? const []);
  }

  @override
  Future<ChatMessage> send({
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    final sender = _data.users.firstWhere((u) => u.userId == senderId);
    final message = ChatMessage(
      id: _data.nextId('m'),
      threadId: threadId,
      senderId: senderId,
      senderName: sender.name,
      text: text,
      sentAt: DateTime.now(),
    );
    _data.messages.putIfAbsent(threadId, () => []).add(message);
    _replace(
      threadId,
      (t) => t.copyWith(lastMessage: text, lastMessageAt: message.sentAt),
    );
    return message;
  }

  @override
  Future<ChatThread> setMuted({
    required String threadId,
    required bool muted,
  }) async => _replace(threadId, (t) => t.copyWith(muted: muted));

  @override
  Future<void> markRead(String threadId) async {
    _replace(threadId, (t) => t.copyWith(unreadCount: 0));
  }

  ChatThread _replace(String threadId, ChatThread Function(ChatThread) change) {
    final index = _data.threads.indexWhere((t) => t.id == threadId);
    if (index < 0) throw StateError('No existe el chat $threadId');
    final updated = change(_data.threads[index]);
    _data.threads[index] = updated;
    return updated;
  }
}
