import 'dart:async';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/chat/data/datasources/i_chat_data_source.dart';

/// Los chats en memoria. Sin servidor no hay tiempo real, pero la pantalla
/// escucha igual: el stream reproduce lo que escribe este mismo dispositivo.
class InMemoryChatDataSource implements IChatDataSource {
  InMemoryChatDataSource(this._data);

  final DummyData _data;

  final _events = StreamController<(String, Map<String, dynamic>)>.broadcast();

  static const _delay = Duration(milliseconds: 200);

  var _messageCounter = 100;

  @override
  String? get currentUserId => _data.session?['userId'] as String?;

  @override
  Future<List<Map<String, dynamic>>> readThreads(
    Map<String, dynamic> filters,
  ) async {
    await Future.delayed(_delay);
    return _data.threads
        .where((r) => filters.entries.every((f) => r[f.key] == f.value))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> threadById(String id) async =>
      _data.threads.where((r) => r['_id'] == id).firstOrNull;

  @override
  Future<Map<String, dynamic>> createThread(Map<String, dynamic> row) async {
    await Future.delayed(_delay);
    final stored = {...row, '_id': _data.nextId('t')};
    _data.threads.add(stored);
    return stored;
  }

  @override
  Future<Map<String, dynamic>> updateThread(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final index = _data.threads.indexWhere((r) => r['_id'] == id);
    if (index < 0) throw StateError('No existe el chat $id');
    _data.threads[index] = {..._data.threads[index], ...changes};
    return _data.threads[index];
  }

  @override
  Future<Map<String, dynamic>?> listingById(String id) async =>
      _data.listings.where((r) => r['_id'] == id).firstOrNull;

  @override
  Future<Map<String, dynamic>> currentUser() async {
    final session = _data.session;
    if (session == null) throw StateError('No hay sesion');
    return session;
  }

  @override
  Future<Object?> readMessages(String threadId) async {
    await Future.delayed(_delay);
    return _data.messages[threadId];
  }

  @override
  Future<String> pushMessage(
    String threadId,
    Map<String, dynamic> message,
  ) async {
    // Las claves salen ordenadas, como las del servidor: ordenarlas ordena los
    // mensajes sin depender del reloj de nadie.
    final key = 'm_${++_messageCounter}';
    _data.messages.putIfAbsent(threadId, () => {})[key] = message;
    _events.add((threadId, {key: message}));
    return key;
  }

  @override
  Stream<Map<String, dynamic>> watchMessageRecords(String threadId) =>
      _events.stream.where((e) => e.$1 == threadId).map((e) => e.$2);
}
