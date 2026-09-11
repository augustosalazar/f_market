// Imprime su avance a proposito: se corre a mano contra el servidor real.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/auth/data/datasources/roble_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/listings/data/datasources/roble_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/profiles/data/datasources/roble_rating_data_source.dart';
import 'package:f_roble_market/features/profiles/data/repositories/rating_repository.dart';
import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/roble_vehicle_catalog_data_source.dart';
import 'package:f_roble_market/features/vehicles/data/repositories/vehicle_catalog_repository.dart';

/// Lo nuevo contra el servidor de verdad: el catalogo precargado, la venta con
/// comprador y las calificaciones.
///
/// Va aparte de `roble_integration_test.dart` para poder correr solo esto.
/// Lo que de verdad comprueba son los **permisos**: una tabla recien creada le
/// da al rol `user` solo INSERT y SELECT, asi que lo que hay que ver es que
/// eso alcance —el catalogo se lee sin sesion, y calificar solo inserta—.
///
/// ```bash
/// set -a && . ./.roble.mcp.env && set +a
/// flutter test test/roble_sales_integration_test.dart --reporter expanded
/// ```
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
    req.add(
      utf8.encode(
        jsonEncode({'tableName': tabla, 'idColumn': '_id', 'idValue': id}),
      ),
    );
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

  test('catalogo, venta con comprador y calificaciones', () async {
    final sello = DateTime.now().millisecondsSinceEpoch;
    final vendedorCliente = nuevoCliente();
    final compradorCliente = nuevoCliente();
    final anonimo = nuevoCliente();

    final catalogoAnonimo = VehicleCatalogRepository(
      RobleVehicleCatalogDataSource(anonimo),
    );
    final listingsVendedor = ListingRepository(
      RobleListingDataSource(vendedorCliente),
    );
    final listingsComprador = ListingRepository(
      RobleListingDataSource(compradorCliente),
    );
    final ratingsComprador = RatingRepository(
      RobleRatingDataSource(compradorCliente),
    );
    final ratingsAnonimo = RatingRepository(RobleRatingDataSource(anonimo));

    CarListing? publicacion;
    UserRating? calificacion;

    try {
      // --- el catalogo se lee sin sesion -----------------------------
      final marcas = await catalogoAnonimo.brands();
      print('  marcas=${marcas.length}');
      expect(marcas, isNotEmpty, reason: 'el catalogo no esta sembrado');
      final marca = marcas.first;
      final modelos = await catalogoAnonimo.modelsOf(marca.id);
      print('  ${marca.name}: ${modelos.length} modelos');
      expect(modelos, isNotEmpty);

      // --- dos cuentas desechables -----------------------------------
      final vendedor = await AuthRepository(
        RobleAuthDataSource(vendedorCliente),
      ).registerWithEmail(
        name: 'Vendedor $sello',
        email: 'vendedor-venta-$sello@ejemplo.test',
        password: 'Prueba!123',
      );
      final comprador = await AuthRepository(
        RobleAuthDataSource(compradorCliente),
      ).registerWithEmail(
        name: 'Comprador $sello',
        email: 'comprador-venta-$sello@ejemplo.test',
        password: 'Prueba!123',
      );

      // --- publicar con marca y modelo del catalogo -------------------
      publicacion = await listingsVendedor.create(
        CarListing(
          id: '',
          sellerId: vendedor.userId,
          sellerName: vendedor.name,
          brand: marca.name,
          model: modelos.first.name,
          year: 2021,
          price: 78500000,
          mileageKm: 42000,
          fuel: FuelType.gasoline,
          transmission: TransmissionType.automatic,
          city: 'Barranquilla',
          description: 'Prueba de integracion $sello',
          images: const [],
          status: ListingStatus.available,
          createdAt: DateTime.now(),
        ),
      );

      // --- cerrar la venta con comprador ------------------------------
      final vendida = await listingsVendedor.markSold(
        listingId: publicacion.id,
        buyerId: comprador.userId,
        buyerName: comprador.name,
      );
      expect(vendida.status, ListingStatus.sold);
      expect(vendida.hasRegisteredSale, isTrue);

      final compras = await listingsComprador.purchasesOf(comprador.userId);
      print('  compras del comprador=${compras.length}');
      expect(compras.map((l) => l.id), contains(publicacion.id));

      // --- calificar --------------------------------------------------
      // Aqui es donde se veria un permiso que falta: `user_rating` es una
      // tabla nueva y calificar es un INSERT.
      calificacion = await ratingsComprador.rate(
        listingId: publicacion.id,
        raterId: comprador.userId,
        raterName: comprador.name,
        ratedId: vendedor.userId,
        ratedRole: RatedRole.seller,
        stars: 5,
        comment: 'Prueba de integracion',
      );

      // La reputacion se ve sin sesion, como el catalogo.
      final recibidas = await ratingsAnonimo.receivedBy(vendedor.userId);
      expect(recibidas.map((r) => r.id), contains(calificacion.id));
      expect(recibidas.first.stars, 5);
      print('  calificacion visible sin sesion: ok');
    } finally {
      if (calificacion != null) {
        await borrarComoAdmin(RobleClient.ratings, calificacion.id);
      }
      if (publicacion != null) {
        await borrarComoAdmin(RobleClient.listings, publicacion.id);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
