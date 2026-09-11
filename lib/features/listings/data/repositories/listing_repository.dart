import 'package:roble/roble.dart';

import 'package:f_roble_market/features/listings/data/datasources/i_listing_data_source.dart';
import 'package:f_roble_market/features/listings/domain/listing_failure.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';

/// El catalogo: decide y traduce, no habla.
///
/// **Es el unico repositorio de la feature**: sirve igual con el datasource de
/// Roble que con el de memoria, porque los dos hablan en filas. Aqui viven la
/// conversion a entidades del `domain/`, la busqueda que la API no sabe hacer,
/// y la traduccion de los fallos a `ListingFailure`, para que la pantalla no
/// vea nunca un codigo HTTP.
class ListingRepository implements IListingRepository {
  ListingRepository(this._source);

  final IListingDataSource _source;

  @override
  Future<List<CarListing>> search(ListingFilter filter) async {
    // La API de lectura solo filtra por igualdad, asi que el texto y los
    // rangos se resuelven aqui. Cuando el catalogo crezca esto se cambia por
    // una consulta guardada; hoy seria complicarlo antes de tiempo.
    final rows = await _guard(_source.readListings);
    final query = filter.query.trim().toLowerCase();

    final result = rows.map(_toListing).where((l) {
      if (query.isNotEmpty &&
          !'${l.brand} ${l.model} ${l.year} ${l.city}'
              .toLowerCase()
              .contains(query)) {
        return false;
      }
      if (filter.brand != null && l.brand != filter.brand) return false;
      if (filter.minPrice != null && l.price < filter.minPrice!) return false;
      if (filter.maxPrice != null && l.price > filter.maxPrice!) return false;
      if (filter.minYear != null && l.year < filter.minYear!) return false;
      return true;
    }).toList();

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<CarListing?> byId(String id) async {
    final row = await _guard(() => _source.listingById(id));
    return row == null ? null : _toListing(row);
  }

  @override
  Future<List<CarListing>> bySeller(String sellerId) async {
    final rows = await _guard(
      () => _source.readListings(filters: {'seller_id': sellerId}),
    );
    final result = rows.map(_toListing).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<CarListing> create(CarListing listing) async {
    final row = await _guard(
      () => _source.createListing({
        'seller_id': listing.sellerId,
        'seller_name': listing.sellerName,
        'brand': listing.brand,
        'model': listing.model,
        'year': listing.year,
        'price': listing.price,
        'mileage_km': listing.mileageKm,
        'fuel': listing.fuel.name,
        'transmission': listing.transmission.name,
        'city': listing.city,
        'description': listing.description,
        // Tres columnas y no una lista: la API rechaza los arrays JSON en una
        // columna jsonb, y el requisito ya limita a tres fotos.
        //
        // Solo viajan URLs. Una ruta del telefono no le sirve a ningun otro
        // dispositivo, asi que guardarla seria ensuciar la tabla con algo que
        // nadie puede abrir. Mientras no haya almacenamiento, esto va vacio y
        // la tarjeta se pinta con su color.
        'image_1': _url(listing.images.elementAtOrNull(0)),
        'image_2': _url(listing.images.elementAtOrNull(1)),
        'image_3': _url(listing.images.elementAtOrNull(2)),
        'status': listing.status.name,
        'created_at': listing.createdAt.toUtc().toIso8601String(),
      }),
    );
    return _toListing(row);
  }

  @override
  Future<CarListing> changeStatus(String listingId, ListingStatus status) async {
    final row = await _guard(
      () => _source.updateListing(listingId, {
        'status': status.name,
        // Sacarla de «vendido» borra al comprador: si no, la publicacion
        // vuelve al catalogo pero sigue contando como compra de alguien.
        if (status != ListingStatus.sold) ...{
          'buyer_id': null,
          'buyer_name': null,
          'sold_at': null,
        },
      }),
      // `listing` esta acotada por dueno: solo su vendedor la cambia, y a
      // quien no lo sea el servidor le responde 404, el mismo que si no
      // existiera.
      siNoEsta: 'El estado no se pudo cambiar: la publicacion ya no existe, o '
          'no es tuya. Solo su vendedor puede cambiarla.',
    );
    return _toListing(row);
  }

  @override
  Future<CarListing> markSold({
    required String listingId,
    required String buyerId,
    required String buyerName,
  }) async {
    final row = await _guard(
      () => _source.updateListing(listingId, {
        'status': ListingStatus.sold.name,
        'buyer_id': buyerId,
        'buyer_name': buyerName,
        'sold_at': DateTime.now().toUtc().toIso8601String(),
      }),
      siNoEsta: 'La venta no se pudo registrar: la publicacion ya no existe, o '
          'no es tuya. Solo su vendedor puede cerrarla.',
    );
    return _toListing(row);
  }

  @override
  Future<List<CarListing>> purchasesOf(String userId) async {
    final rows = await _guard(
      () => _source.readListings(filters: {'buyer_id': userId}),
    );
    final result = rows.map(_toListing).toList();
    // Por la fecha de la venta, no la de publicacion: lo que ordena un
    // historial de compras es cuando se compro.
    result.sort(
      (a, b) => (b.soldAt ?? b.createdAt).compareTo(a.soldAt ?? a.createdAt),
    );
    return result;
  }

  @override
  Future<List<CarListing>> followedBy(String userId) async {
    final ids = await followedIds(userId);
    if (ids.isEmpty) return const [];
    final rows = await _guard(_source.readListings);
    return rows.map(_toListing).where((l) => ids.contains(l.id)).toList();
  }

  @override
  Future<Set<String>> followedIds(String userId) async {
    final rows = await _guard(() => _source.readFollows({'user_id': userId}));
    return rows.map((r) => r['listing_id'] as String).toSet();
  }

  @override
  Future<bool> toggleFollow({
    required String listingId,
    required String userId,
  }) async {
    final existing = await _guard(
      () => _source.readFollows({'listing_id': listingId, 'user_id': userId}),
    );

    if (existing.isNotEmpty) {
      try {
        await _source.deleteFollow(existing.first['_id'] as String);
      } on RobleApiHttpException catch (e) {
        // Dejar de seguir dos veces a la vez: lo que importaba ya se cumplio.
        if (e.statusCode != 404) rethrow;
      }
      return false;
    }

    await _guard(
      () => _source.createFollow({
        'listing_id': listingId,
        'user_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return true;
  }

  @override
  Future<List<String>> followerIdsOf(String listingId) async {
    final rows = await _guard(
      () => _source.readFollows({'listing_id': listingId}),
    );
    return rows.map((r) => r['user_id'] as String).toList();
  }

  /// Aqui mueren las excepciones del paquete.
  ///
  /// Un 404 con propiedad por fila significa «no existe **o** no es tuya»: el
  /// servidor contesta igual a proposito, para no confirmar que existe algo
  /// ajeno. Sin traducirlo, la pantalla dice «no existe» y manda a buscar el
  /// fallo donde no esta.
  Future<T> _guard<T>(Future<T> Function() action, {String? siNoEsta}) async {
    try {
      return await action();
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 404 && siNoEsta != null) throw ListingFailure(siNoEsta);
      if (e.statusCode == 403) {
        throw ListingFailure('Tu cuenta no puede hacer esto.');
      }
      throw ListingFailure(e.message);
    } on RobleApiException catch (e) {
      throw ListingFailure(e.message);
    }
  }

  /// La foto solo si es algo que otro dispositivo pueda abrir.
  static String? _url(String? path) =>
      path != null && path.startsWith('http') ? path : null;

  CarListing _toListing(Map<String, dynamic> row) => CarListing(
    id: row['_id'] as String,
    sellerId: row['seller_id'] as String,
    sellerName: (row['seller_name'] as String?) ?? 'Sin nombre',
    brand: row['brand'] as String,
    model: row['model'] as String,
    year: (row['year'] as num).toInt(),
    // `numeric` viaja como cadena: convertirlo con `as num` reventaria.
    price: double.parse('${row['price']}'),
    mileageKm: (row['mileage_km'] as num).toInt(),
    fuel: FuelType.values.byName(row['fuel'] as String),
    transmission: TransmissionType.values.byName(row['transmission'] as String),
    city: (row['city'] as String?) ?? '',
    description: (row['description'] as String?) ?? '',
    images: [
      for (final columna in const ['image_1', 'image_2', 'image_3'])
        if (row[columna] is String && (row[columna] as String).isNotEmpty)
          row[columna] as String,
    ],
    status: ListingStatus.fromName(row['status'] as String),
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    buyerId: _text(row['buyer_id']),
    buyerName: _text(row['buyer_name']),
    soldAt: row['sold_at'] == null
        ? null
        : DateTime.parse('${row['sold_at']}').toLocal(),
  );

  /// Una columna nueva llega nula en las filas de antes, y vacia no es lo
  /// mismo que puesta: las dos cosas significan «sin comprador».
  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
