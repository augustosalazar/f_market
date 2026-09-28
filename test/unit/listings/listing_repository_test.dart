import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/features/listings/data/datasources/i_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/listing_failure.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';

/// Una fuente de datos falsa: devuelve las filas que la prueba le diga.
class FakeListingDataSource extends Fake implements IListingDataSource {
  List<Map<String, dynamic>> filas = [];
  Object? error;

  @override
  Future<Map<String, dynamic>?> listingById(String id) async =>
      filas.where((f) => f['_id'] == id).firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> searchListings({
    required String text,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
  }) async => filas;

  @override
  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> changes,
  ) async {
    if (error != null) throw error!;
    return {...filas.first, ...changes};
  }
}

/// Una fila como las que manda el servidor. Cada prueba cambia solo lo que le
/// importa.
Map<String, dynamic> fila({
  String id = 'l_1',
  String brand = 'Mazda',
  Object price = '78500000',
  String createdAt = '2026-09-01T10:00:00Z',
}) => {
  '_id': id,
  'seller_id': 'u_ana',
  'seller_name': 'Ana Torres',
  'brand': brand,
  'model': '3',
  'year': 2021,
  'price': price,
  'mileage_km': 42000,
  'fuel': 'gasoline',
  'transmission': 'automatic',
  'city': 'Barranquilla',
  'description': '',
  'image_1': 'https://ejemplo.test/foto.jpg',
  'image_2': '',
  'image_3': null,
  'status': 'available',
  'created_at': createdAt,
};

void main() {
  late FakeListingDataSource fuente;
  late ListingRepository repositorio;

  setUp(() {
    fuente = FakeListingDataSource();
    repositorio = ListingRepository(fuente);
  });

  group('convertir una fila', () {
    test('el precio llega como texto y se lee como numero', () async {
      // Postgres manda las columnas `numeric` como cadena.
      fuente.filas = [fila(price: '78500000.00')];

      final carro = await repositorio.byId('l_1');

      expect(carro!.price, 78500000);
    });

    test('solo cuentan las fotos que tienen URL', () async {
      fuente.filas = [fila()];

      final carro = await repositorio.byId('l_1');

      expect(carro!.images, ['https://ejemplo.test/foto.jpg']);
    });

    test('si no existe, devuelve null', () async {
      expect(await repositorio.byId('no_existe'), isNull);
    });
  });

  group('buscar', () {
    test('filtra por marca y pone primero lo mas reciente', () async {
      fuente.filas = [
        fila(id: 'viejo', brand: 'Kia', createdAt: '2026-01-01T00:00:00Z'),
        fila(id: 'otra_marca', brand: 'Mazda'),
        fila(id: 'nuevo', brand: 'Kia', createdAt: '2026-09-01T00:00:00Z'),
      ];

      final carros = await repositorio.search(
        const ListingFilter(brand: 'Kia'),
      );

      expect(carros.map((c) => c.id), ['nuevo', 'viejo']);
    });
  });

  group('traducir errores', () {
    test('un 404 al cambiar el estado dice que no es tuya', () {
      // Con propiedad por fila, el servidor responde lo mismo a «no existe» y
      // a «no es tuya».
      fuente.filas = [fila()];
      fuente.error = const RobleApiNotFoundException('No encontrado');

      expect(
        repositorio.changeStatus('l_1', ListingStatus.sold),
        throwsA(
          isA<ListingFailure>().having(
            (f) => f.message,
            'message',
            contains('no es tuya'),
          ),
        ),
      );
    });
  });
}
