// Imprime su avance a proposito: se corre a mano contra el servidor real.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/auth/data/datasources/roble_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/listings/data/datasources/roble_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';

/// La sesion de invitado contra el servidor de verdad.
///
/// Comprueba las tres cosas que solo se ven en produccion:
///
/// 1. **El catalogo se ve siendo invitado.** Es la trampa: un invitado tiene
///    `isLoggedIn == true` pero el rol `anonymous` solo lee lo suyo, asi que la
///    lectura normal le devolveria cero filas **sin ningun error**.
/// 2. **Puede dejar de seguir**, que es el permiso `listing_follow:delete` con
///    alcance `own` que hubo que conceder: de fabrica ese rol no borra, y el
///    fallo aparece en el segundo toque de la estrella.
/// 3. **Al ascender conserva lo suyo**, porque el `userId` no cambia.
///
/// ```bash
/// set -a && . ./.roble.mcp.env && set +a
/// flutter test test/roble_guest_integration_test.dart --reporter expanded
/// ```
///
/// **El servidor limita las sesiones de invitado a 3 por hora y por IP.** Si
/// sale 429, no es un fallo de la app: espera.
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
  final base =
      Platform.environment['ROBLE_BASE_URL'] ??
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

  test('un invitado ve el catalogo, sigue, deja de seguir y se registra', () async {
    final sello = DateTime.now().millisecondsSinceEpoch;
    final invitadoCliente = nuevoCliente();
    final vendedorCliente = nuevoCliente();

    final invitadoAuth = AuthRepository(RobleAuthDataSource(invitadoCliente));
    final listingsInvitado = ListingRepository(
      RobleListingDataSource(invitadoCliente),
    );
    final listingsVendedor = ListingRepository(
      RobleListingDataSource(vendedorCliente),
    );

    CarListing? publicada;
    var invitadoVivo = false;
    var vendedorVivo = false;

    try {
      // Hace falta algo que seguir. Si el catalogo esta vacio se publica con
      // una cuenta desechable, que se borra al final igual que la fila.
      var catalogo = await listingsInvitado.search(const ListingFilter());
      if (catalogo.isEmpty) {
        final vendedor = await AuthRepository(
          RobleAuthDataSource(vendedorCliente),
        ).registerWithEmail(
          name: 'Vendedor $sello',
          email: 'vendedor-invitado-$sello@ejemplo.test',
          password: 'Prueba!123',
        );
        vendedorVivo = true;
        publicada = await listingsVendedor.create(
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
            description: 'Prueba de sesion de invitado $sello',
            images: const [],
            status: ListingStatus.available,
            createdAt: DateTime.now(),
          ),
        );
      }

      // --- 1. entra sin cuenta ----------------------------------------
      final invitado = await invitadoAuth.signInAnonymously();
      invitadoVivo = true;
      print('  invitado -> ${invitado.userId} isAnonymous=${invitado.isAnonymous}');
      expect(invitado.isAnonymous, isTrue);
      expect(invitadoCliente.isGuest, isTrue);

      // --- 2. y aun asi ve el catalogo --------------------------------
      catalogo = await listingsInvitado.search(const ListingFilter());
      print('  catalogo siendo invitado -> ${catalogo.length} publicaciones');
      expect(
        catalogo,
        isNotEmpty,
        reason: 'el invitado esta leyendo con su rol en vez de publicRead',
      );
      final objetivo = publicada ?? catalogo.first;
      expect(await listingsInvitado.byId(objetivo.id), isNotNull);

      // --- 3. sigue, y deja de seguir ---------------------------------
      final siguiendo = await listingsInvitado.toggleFollow(
        listingId: objetivo.id,
        userId: invitado.userId,
      );
      expect(siguiendo, isTrue);
      expect(await listingsInvitado.followedIds(invitado.userId),
          contains(objetivo.id));

      // Aqui es donde falla si al rol `anonymous` le falta `delete` con
      // alcance `own`.
      final dejoDeSeguir = await listingsInvitado.toggleFollow(
        listingId: objetivo.id,
        userId: invitado.userId,
      );
      expect(dejoDeSeguir, isFalse);
      expect(await listingsInvitado.followedIds(invitado.userId), isEmpty);
      print('  seguir y dejar de seguir: ok');

      // Deja uno puesto, para ver si sobrevive al registro.
      await listingsInvitado.toggleFollow(
        listingId: objetivo.id,
        userId: invitado.userId,
      );
      // Un invitado no puede ejecutar consultas: va por `public-read`.
      expect(
        (await listingsInvitado.followedBy(invitado.userId)).map((l) => l.id),
        [objetivo.id],
      );

      // --- 4. guarda su cuenta y conserva lo suyo ----------------------
      final cuenta = await invitadoAuth.upgradeAccount(
        email: 'invitado-$sello@ejemplo.test',
        password: 'Prueba!123',
        name: 'Ex Invitado $sello',
      );
      print('  ascendido -> ${cuenta.userId} isAnonymous=${cuenta.isAnonymous}');
      expect(cuenta.isAnonymous, isFalse);
      // El mismo usuario: es lo que hace que no se mueva un solo dato.
      expect(cuenta.userId, invitado.userId);
      expect(await listingsInvitado.followedIds(cuenta.userId),
          contains(objetivo.id));
      // Ya con cuenta, lo seguido llega por la consulta guardada.
      expect(
        (await listingsInvitado.followedBy(cuenta.userId)).map((l) => l.id),
        [objetivo.id],
      );

      // Y ya con cuenta, el catalogo se lee por la via normal.
      expect(invitadoCliente.isGuest, isFalse);
      expect(await listingsInvitado.search(const ListingFilter()), isNotEmpty);
      print('  lo seguido sobrevive al registro: ok');

      // --- limpieza ----------------------------------------------------
      await listingsInvitado.toggleFollow(
        listingId: objetivo.id,
        userId: cuenta.userId,
      );
      if (publicada != null) {
        await listingsVendedor.changeStatus(
          publicada.id,
          ListingStatus.withdrawn,
        );
      }
    } finally {
      // Las cuentas desechables se borran ellas mismas: el token de proyecto
      // no hace falta para esto.
      if (invitadoVivo) {
        await invitadoCliente.db.deleteAccount().catchError((Object e) {
          print('  AVISO no se borro el invitado: $e');
        });
      }
      if (vendedorVivo) {
        await vendedorCliente.db.deleteAccount().catchError((Object e) {
          print('  AVISO no se borro el vendedor: $e');
        });
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
