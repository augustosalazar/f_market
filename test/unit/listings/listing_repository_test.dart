import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/features/listings/data/datasources/i_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/listing_failure.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';

/// Una fuente de datos falsa: devuelve las filas que la prueba le diga.
class FakeListingDataSource extends Fake implements IListingDataSource {
  List<Map<String, dynamic>> rowsToReturn = [];
  Object? errorToThrow;

  @override
  Future<Map<String, dynamic>?> listingById(String id) async =>
      rowsToReturn.where((f) => f['_id'] == id).firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> searchListings({
    required String text,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
  }) async => rowsToReturn;

  @override
  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> changes,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return {...rowsToReturn.first, ...changes};
  }
}

/// Una fila como las que manda el servidor. Cada prueba cambia solo lo que le
/// importa.
Map<String, dynamic> buildRow({
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
  late FakeListingDataSource fakeListingDataSource;
  late ListingRepository listingRepository;

  setUp(() {
    fakeListingDataSource = FakeListingDataSource();
    listingRepository = ListingRepository(fakeListingDataSource);
  });

  group('convertir una fila', () {
    test('el precio llega como texto y se lee como numero', () async {
      // Postgres manda las columnas `numeric` como cadena.
      fakeListingDataSource.rowsToReturn = [buildRow(price: '78500000.00')];

      final listing = await listingRepository.byId('l_1');

      expect(listing!.price, 78500000);
    });

    test('solo cuentan las fotos que tienen URL', () async {
      fakeListingDataSource.rowsToReturn = [buildRow()];

      final listing = await listingRepository.byId('l_1');

      expect(listing!.images, ['https://ejemplo.test/foto.jpg']);
    });

    test('si no existe, devuelve null', () async {
      expect(await listingRepository.byId('no_existe'), isNull);
    });
  });

  group('buscar', () {
    test('filtra por marca y pone primero lo mas reciente', () async {
      fakeListingDataSource.rowsToReturn = [
        buildRow(id: 'viejo', brand: 'Kia', createdAt: '2026-01-01T00:00:00Z'),
        buildRow(id: 'otra_marca', brand: 'Mazda'),
        buildRow(id: 'nuevo', brand: 'Kia', createdAt: '2026-09-01T00:00:00Z'),
      ];

      final listings = await listingRepository.search(
        const ListingFilter(brand: 'Kia'),
      );

      expect(listings.map((c) => c.id), ['nuevo', 'viejo']);
    });
  });

  group('traducir errores', () {
    test('un 404 al cambiar el estado dice que no es tuya', () {
      // Con propiedad por fila, el servidor responde lo mismo a «no existe» y
      // a «no es tuya».
      fakeListingDataSource.rowsToReturn = [buildRow()];
      fakeListingDataSource.errorToThrow = const RobleApiNotFoundException(
        'No encontrado',
      );

      expect(
        listingRepository.changeStatus('l_1', ListingStatus.sold),
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
