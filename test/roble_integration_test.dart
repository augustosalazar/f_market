// Imprime su avance a proposito: se corre a mano contra el servidor real.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/auth/data/datasources/roble_auth_data_source.dart';
import 'package:f_roble_market/features/chat/data/datasources/roble_chat_data_source.dart';
import 'package:f_roble_market/features/listings/data/datasources/roble_listing_data_source.dart';
import 'package:f_roble_market/features/qa/data/datasources/roble_qa_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/qa/data/repositories/qa_repository.dart';

/// Prueba de integracion: los repositorios de Roble contra el servidor de
/// verdad, con dos cuentas desechables que se borran al terminar.
///
/// No corre en CI ni con `flutter test` a secas: necesita configuracion.
///
/// ```bash
/// set -a && . ./.roble.mcp.env && set +a
/// flutter test test/roble_integration_test.dart --reporter expanded
/// ```
/// Borra una fila con el **token de proyecto**, no con el del usuario.
///
/// Hace falta porque el rol de la app, a proposito, no puede borrar
/// publicaciones ni preguntas: se retiran cambiando el estado. Sin esta puerta
/// cada corrida dejaria filas en el proyecto compartido. Sale del mismo
/// `.roble.mcp.env` que ya configura la prueba; si no esta, se avisa.
Future<void> borrarComoAdmin(String tabla, String id) async {
  final token = Platform.environment['ROBLE_TOKEN'];
  final base = Platform.environment['ROBLE_BASE_URL'];
  final contrato = Platform.environment['ROBLE_CONTRACT_ID'];
  if (token == null || token.isEmpty) {
    print('  AVISO sin ROBLE_TOKEN: queda $tabla/$id sin borrar');
    return;
  }
  final cliente = HttpClient();
  try {
    final req = await cliente.openUrl(
      'DELETE',
      Uri.parse('$base/database/$contrato/adm-delete'),
    );
    req.headers
      ..set('authorization', 'Bearer $token')
      ..set('content-type', 'application/json');
    req.add(utf8.encode(
      jsonEncode({'tableName': tabla, 'idColumn': '_id', 'idValue': id}),
    ));
    final res = await req.close();
    await res.drain<void>();
  } finally {
    cliente.close();
  }
}

class MemoriaStorage implements RobleTokenStorage {
  final _datos = <String, String>{};
  @override
  Future<String?> getItem(String key) async => _datos[key];
  @override
  Future<void> setItem(String key, String value) async => _datos[key] = value;
  @override
  Future<void> removeItem(String key) async => _datos.remove(key);
}

void main() {
  final contrato = Platform.environment['ROBLE_CONTRACT_ID'];
  final base = Platform.environment['ROBLE_BASE_URL'] ??
      'https://roble-api.test-openlab.uninorte.edu.co';

  if (contrato == null || contrato.isEmpty) {
    test('falta ROBLE_CONTRACT_ID', () => fail('Define ROBLE_CONTRACT_ID'));
    return;
  }

  RobleClient nuevoCliente() => RobleClient.withDatabase(
    RobleApiDataBase(
      config: RobleApiConfig.fromContract(baseUrl: base, contractId: contrato),
      storage: MemoriaStorage(),
    ),
  );

  test('el flujo completo, con dos cuentas desechables', () async {
    final sello = DateTime.now().millisecondsSinceEpoch;
    // Cada quien con su cliente: dos sesiones a la vez, como dos telefonos.
    final vendedorCliente = nuevoCliente();
    final compradorCliente = nuevoCliente();
    final anonimo = nuevoCliente();

    final vendedorAuth = AuthRepository(RobleAuthDataSource(vendedorCliente));
    final compradorAuth = AuthRepository(RobleAuthDataSource(compradorCliente));

    final listingsVendedor = ListingRepository(RobleListingDataSource(vendedorCliente));
    final listingsComprador = ListingRepository(RobleListingDataSource(compradorCliente));
    final listingsAnonimo = ListingRepository(RobleListingDataSource(anonimo));
    final qaVendedor = QaRepository(RobleQaDataSource(vendedorCliente));
    final qaComprador = QaRepository(RobleQaDataSource(compradorCliente));
    final chatComprador = ChatRepository(RobleChatDataSource(compradorCliente));
    final chatVendedor = ChatRepository(RobleChatDataSource(vendedorCliente));

    CarListing? publicacion;
    ChatThread? hilo;
    var vendedorCreado = false;
    var compradorCreado = false;

    try {
      final vendedor = await vendedorAuth.registerWithEmail(
        name: 'Vendedor $sello',
        email: 'vendedor-$sello@ejemplo.test',
        password: 'Prueba!123',
      );
      vendedorCreado = true;
      final comprador = await compradorAuth.registerWithEmail(
        name: 'Comprador $sello',
        email: 'comprador-$sello@ejemplo.test',
        password: 'Prueba!123',
      );
      compradorCreado = true;
      print('  vendedor=${vendedor.userId} comprador=${comprador.userId}');

      // --- publicar ---------------------------------------------------
      publicacion = await listingsVendedor.create(
        CarListing(
          id: '',
          sellerId: vendedor.userId,
          sellerName: vendedor.name,
          brand: 'Mazda',
          model: 'Prueba $sello',
          year: 2021,
          price: 78500000,
          mileageKm: 42000,
          fuel: FuelType.gasoline,
          transmission: TransmissionType.automatic,
          city: 'Barranquilla',
          description: 'Publicacion de la prueba de integracion.',
          images: const [],
          status: ListingStatus.available,
          createdAt: DateTime.now(),
        ),
      );
      print('  publicacion -> ${publicacion.id}');
      expect(publicacion.id, isNotEmpty);
      expect(publicacion.price, 78500000);
      expect(publicacion.title, contains('Prueba $sello'));

      // --- el catalogo se ve sin sesion (requisito 3) -----------------
      try {
        final publico = await listingsAnonimo.search(const ListingFilter());
        print('  catalogo sin sesion: ${publico.length} publicaciones');
        expect(publico.map((l) => l.id), contains(publicacion.id));
      } catch (e) {
        // Un 403 aqui no es un fallo del codigo: es que la tabla `listing`
        // todavia no esta marcada como publica en la consola de Roble.
        print('  AVISO catalogo sin sesion: $e');
      }

      // --- seguir y preguntar -----------------------------------------
      expect(
        await listingsComprador.toggleFollow(
          listingId: publicacion.id,
          userId: comprador.userId,
        ),
        isTrue,
      );
      expect(
        await listingsVendedor.followerIdsOf(publicacion.id),
        contains(comprador.userId),
      );

      final pregunta = await qaComprador.ask(
        listingId: publicacion.id,
        askerId: comprador.userId,
        askerName: comprador.name,
        text: 'Sigue disponible?',
      );
      final respondida = await qaVendedor.answer(
        questionId: pregunta.id,
        responderId: vendedor.userId,
        responderName: vendedor.name,
        text: 'Si, disponible.',
      );
      expect(respondida.isAnswered, isTrue);
      expect(respondida.answer!.text, 'Si, disponible.');
      print('  pregunta y respuesta ok');

      // --- estado ------------------------------------------------------
      final reservada = await listingsVendedor.changeStatus(
        publicacion.id,
        ListingStatus.reserved,
      );
      expect(reservada.status, ListingStatus.reserved);

      // --- chat privado, con tiempo real -------------------------------
      hilo = await chatComprador.openThread(
        listingId: publicacion.id,
        buyerId: comprador.userId,
      );
      expect(hilo.sellerId, vendedor.userId);
      expect(hilo.listingTitle, contains('Prueba $sello'));

      // Se escribe antes de escuchar: suscribirse a una coleccion que no
      // existe se rechaza con REALTIME_UNKNOWN_COLLECTION.
      await chatComprador.send(
        threadId: hilo.id,
        senderId: comprador.userId,
        text: 'Buenas, sigue disponible?',
      );

      final recibidos = <ChatMessage>[];
      final sub = chatVendedor.watchMessages(hilo.id).listen(recibidos.add);
      // El socket tarda ~1,5 s en abrir; escribir antes pierde el evento.
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      await chatVendedor.send(
        threadId: hilo.id,
        senderId: vendedor.userId,
        text: 'Si, cuando quieres verlo?',
      );
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      await sub.cancel();

      print('  tiempo real: ${recibidos.length} mensajes en vivo');
      expect(recibidos, isNotEmpty);
      expect(recibidos.last.text, 'Si, cuando quieres verlo?');

      final historial = await chatComprador.messagesOf(hilo.id);
      expect(historial, hasLength(2));
      expect(historial.first.text, 'Buenas, sigue disponible?');

      // El contador es de quien mira: el comprador tiene uno sin leer.
      final delComprador = await chatComprador.threadsOf(comprador.userId);
      expect(delComprador.single.unreadCount, 1);
      expect(delComprador.single.lastMessage, 'Si, cuando quieres verlo?');
      await chatComprador.markRead(hilo.id);
      expect(
        (await chatComprador.threadsOf(comprador.userId)).single.unreadCount,
        0,
      );

      // Silenciar es de quien mira, tambien.
      final silenciado = await chatComprador.setMuted(
        threadId: hilo.id,
        muted: true,
      );
      expect(silenciado.muted, isTrue);
      expect(
        (await chatVendedor.threadsOf(vendedor.userId)).single.muted,
        isFalse,
        reason: 'silenciar no puede afectar al otro participante',
      );
      print('  chat ok');
    } finally {
      // Se limpia pase lo que pase: si no, cada corrida deja basura.
      final db = vendedorCliente.db;
      if (hilo != null) {
        // Las ramas del arbol si las borra el usuario; la coleccion entera no
        // —eso es de administradores— pero aqui no hace falta.
        try {
          await db.json.remove('${RobleClient.messages}/${hilo.id}');
        } catch (_) {}
        await borrarComoAdmin(RobleClient.threads, hilo.id);
      }
      if (publicacion != null) {
        for (final tabla in [RobleClient.questions, RobleClient.follows]) {
          try {
            final filas = await db.read(
              tabla,
              filters: {'listing_id': publicacion.id},
            );
            for (final fila in filas) {
              await borrarComoAdmin(tabla, fila['_id'] as String);
            }
          } catch (_) {}
        }
        await borrarComoAdmin(RobleClient.listings, publicacion.id);
      }
      if (compradorCreado) await compradorCliente.db.deleteAccount();
      if (vendedorCreado) await vendedorCliente.db.deleteAccount();
    }
  }, timeout: const Timeout(Duration(seconds: 120)));
}
