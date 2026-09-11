import 'package:roble/roble.dart';

import 'package:f_roble_market/features/chat/data/datasources/i_chat_data_source.dart';
import 'package:f_roble_market/features/chat/domain/chat_failure.dart';
import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';

/// El chat privado: decide y traduce, no habla.
///
/// Lo que decide, y por eso no esta en el datasource: que la cabecera vive en
/// SQL y los mensajes en el arbol, que ordenar por la clave del servidor es
/// mejor que por el reloj del telefono que envio, y que el contador de sin
/// leer que se ve es el de quien mira y no el del otro.
class ChatRepository implements IChatRepository {
  ChatRepository(this._source);

  final IChatDataSource _source;

  @override
  Future<List<ChatThread>> threadsOf(String userId) async {
    // `read` filtra por igualdad y varios filtros se combinan con Y, asi que
    // «comprador O vendedor» son dos lecturas.
    final asBuyer = await _guard(() => _source.readThreads({'buyer_id': userId}));
    final asSeller = await _guard(
      () => _source.readThreads({'seller_id': userId}),
    );

    final byId = <String, ChatThread>{};
    for (final row in [...asBuyer, ...asSeller]) {
      final thread = _toThread(row);
      byId[thread.id] = thread;
    }
    final result = byId.values.toList();
    result.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return result;
  }

  @override
  Future<ChatThread?> threadById(String threadId) async {
    final row = await _guard(() => _source.threadById(threadId));
    return row == null ? null : _toThread(row);
  }

  @override
  Future<List<ChatThread>> threadsOfListing(String listingId) async {
    final rows = await _guard(
      () => _source.readThreads({'listing_id': listingId}),
    );
    final result = rows.map(_toThread).toList();
    result.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return result;
  }

  @override
  Future<ChatThread> openThread({
    required String listingId,
    required String buyerId,
  }) async {
    final existing = await _guard(
      () => _source.readThreads({'listing_id': listingId, 'buyer_id': buyerId}),
    );
    if (existing.isNotEmpty) return _toThread(existing.first);

    final listing = await _guard(() => _source.listingById(listingId));
    if (listing == null) {
      throw ChatFailure('Esa publicacion ya no existe.');
    }
    // Quien abre el chat es siempre el comprador, o sea la sesion actual.
    final buyer = await _guard(_source.currentUser);
    final images = [
      for (final columna in const ['image_1', 'image_2', 'image_3'])
        if (listing[columna] is String) listing[columna] as String,
    ];

    final row = await _guard(
      () => _source.createThread({
        'listing_id': listingId,
        'listing_title':
            '${listing['brand']} ${listing['model']} ${listing['year']}',
        'listing_cover': images.isEmpty ? null : images.first,
        'buyer_id': buyerId,
        'buyer_name': buyer['name'],
        'seller_id': listing['seller_id'],
        'seller_name': listing['seller_name'],
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'buyer_muted': false,
        'seller_muted': false,
        'buyer_unread': 0,
        'seller_unread': 0,
      }),
    );
    return _toThread(row);
  }

  @override
  Future<List<ChatMessage>> messagesOf(String threadId) async {
    final data = await _guard(() => _source.readMessages(threadId));
    if (data is! Map) return const [];

    final messages = data.entries
        .map((e) => _toMessage(threadId, '${e.key}', e.value))
        .whereType<ChatMessage>()
        .toList();
    // Por clave, no por fecha: la del servidor es monotona y la del telefono
    // que envio puede ir adelantada o atrasada.
    messages.sort((a, b) => a.id.compareTo(b.id));
    return messages;
  }

  @override
  Stream<ChatMessage> watchMessages(String threadId) {
    return _source.watchMessageRecords(threadId).expand(
      (record) => record.entries
          .map((e) => _toMessage(threadId, e.key, e.value))
          .whereType<ChatMessage>(),
    );
  }

  @override
  Future<ChatMessage> send({
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    final row = await _guard(() => _source.threadById(threadId));
    if (row == null) throw ChatFailure('Ese chat ya no existe.');

    final sentAt = DateTime.now().toUtc();
    final senderIsSeller = senderId == row['seller_id'];
    final senderName =
        '${senderIsSeller ? row['seller_name'] : row['buyer_name']}';

    final key = await _guard(
      () => _source.pushMessage(threadId, {
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'sent_at': sentAt.toIso8601String(),
      }),
    );

    // La cabecera guarda el ultimo mensaje para pintar la lista sin abrir cada
    // hilo, y sube el contador del que recibe.
    final recipientIsSeller = !senderIsSeller;
    final recipientUnread = _int(
      row[recipientIsSeller ? 'seller_unread' : 'buyer_unread'],
    );
    await _guard(
      () => _source.updateThread(threadId, {
        'last_message': text,
        'last_message_at': sentAt.toIso8601String(),
        if (recipientIsSeller) 'seller_unread': recipientUnread + 1,
        if (!recipientIsSeller) 'buyer_unread': recipientUnread + 1,
      }),
    );

    return ChatMessage(
      id: key,
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: sentAt.toLocal(),
    );
  }

  @override
  Future<ChatThread> setMuted({
    required String threadId,
    required bool muted,
  }) async {
    final thread = await threadById(threadId);
    if (thread == null) throw ChatFailure('Ese chat ya no existe.');
    // Silenciar es de quien mira: cada participante tiene su interruptor.
    final field = _source.currentUserId == thread.sellerId
        ? 'seller_muted'
        : 'buyer_muted';
    final row = await _guard(
      () => _source.updateThread(threadId, {field: muted}),
    );
    return _toThread(row);
  }

  @override
  Future<void> markRead(String threadId) async {
    final thread = await threadById(threadId);
    if (thread == null || thread.unreadCount == 0) return;
    final field = _source.currentUserId == thread.sellerId
        ? 'seller_unread'
        : 'buyer_unread';
    await _guard(() => _source.updateThread(threadId, {field: 0}));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) {
        throw ChatFailure('Tu cuenta no puede hacer esto.');
      }
      throw ChatFailure(e.message);
    } on RobleApiException catch (e) {
      throw ChatFailure(e.message);
    }
  }

  ChatMessage? _toMessage(String threadId, String key, Object? data) {
    if (data is! Map) return null;
    return ChatMessage(
      id: key,
      threadId: threadId,
      senderId: '${data['sender_id']}',
      senderName: '${data['sender_name']}',
      text: '${data['text']}',
      sentAt: DateTime.parse('${data['sent_at']}').toLocal(),
    );
  }

  ChatThread _toThread(Map<String, dynamic> row) {
    final createdAt = DateTime.parse(row['created_at'] as String).toLocal();
    final viewerIsSeller = _source.currentUserId == row['seller_id'];
    return ChatThread(
      id: row['_id'] as String,
      listingId: row['listing_id'] as String,
      listingTitle: (row['listing_title'] as String?) ?? 'Publicacion',
      listingCover: row['listing_cover'] as String?,
      buyerId: row['buyer_id'] as String,
      buyerName: (row['buyer_name'] as String?) ?? 'Comprador',
      sellerId: row['seller_id'] as String,
      sellerName: (row['seller_name'] as String?) ?? 'Vendedor',
      lastMessage: (row['last_message'] as String?) ?? '',
      lastMessageAt: row['last_message_at'] == null
          ? createdAt
          : DateTime.parse(row['last_message_at'] as String).toLocal(),
      // Lo que ve quien mira: el contador del otro no es asunto suyo.
      unreadCount: viewerIsSeller
          ? _int(row['seller_unread'])
          : _int(row['buyer_unread']),
      muted: viewerIsSeller
          ? row['seller_muted'] == true
          : row['buyer_muted'] == true,
    );
  }

  static int _int(Object? value) => value == null ? 0 : (value as num).toInt();
}
