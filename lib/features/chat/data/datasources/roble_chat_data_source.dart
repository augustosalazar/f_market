import 'package:roble/roble.dart';

import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/chat/data/datasources/i_chat_data_source.dart';


/// Habla con Roble sobre chats. No decide nada.
///
/// Los dos almacenes que usa el chat viven aqui: la cabecera del hilo es una
/// tabla SQL —forma fija, y hay que filtrarla por comprador o por vendedor— y
/// los mensajes van al arbol JSON, porque el tiempo real solo emite eventos de
/// colecciones del arbol. `watchTable` existe en el paquete pero el servidor
/// rechaza esas suscripciones.
class RobleChatDataSource implements IChatDataSource {
  RobleChatDataSource(this._client);

  final RobleClient _client;

  static const threads = RobleClient.threads;

  RobleApiDataBase get _db => _client.db;

  /// La ruta del hilo en el arbol: `chat_message/<threadId>`.
  String pathOf(String threadId) => '${RobleClient.messages}/$threadId';

  /// Quien mira, para decidir cual de los dos interruptores del hilo es suyo.
  @override
  String? get currentUserId => _client.currentUserId;

  @override
  Future<List<Map<String, dynamic>>> readThreads(Map<String, dynamic> filters) =>
      _db.read(threads, filters: filters);

  @override
  Future<Map<String, dynamic>?> threadById(String id) =>
      _db.getById(threads, id);

  @override
  Future<Map<String, dynamic>> createThread(Map<String, dynamic> row) =>
      _db.create(threads, row);

  @override
  Future<Map<String, dynamic>> updateThread(
    String id,
    Map<String, dynamic> changes,
  ) => _db.update(threads, id, changes);

  @override
  Future<Map<String, dynamic>?> listingById(String id) =>
      _db.getById(RobleClient.listings, id);

  @override
  Future<Map<String, dynamic>> currentUser() => _db.currentUser();

  @override
  Future<Object?> readMessages(String threadId) => _db.json.read(pathOf(threadId));

  /// Devuelve la clave que genera el servidor, que va ordenada por tiempo.
  @override
  Future<String> pushMessage(String threadId, Map<String, dynamic> message) =>
      _db.json.push(pathOf(threadId), message);

  /// Lo que llega por el socket, ya desenvuelto: en un `push`, el registro es
  /// `{claveNueva: dato}`. Devolverlo como mapa evita que el tipo del paquete
  /// se cuele en el repositorio.
  @override
  Stream<Map<String, dynamic>> watchMessageRecords(String threadId) => _db.json
      .watch(pathOf(threadId))
      .map((change) => change.record ?? const <String, dynamic>{});
}
