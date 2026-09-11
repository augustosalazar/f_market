import 'listing_status.dart';

/// Combustible del vehiculo. Es una caracteristica basica del formulario.
enum FuelType {
  gasoline('Gasolina'),
  diesel('Diesel'),
  hybrid('Hibrido'),
  electric('Electrico'),
  gas('Gas');

  const FuelType(this.label);
  final String label;
}

enum TransmissionType {
  manual('Mecanica'),
  automatic('Automatica');

  const TransmissionType(this.label);
  final String label;
}

/// Una publicacion de venta de carro.
///
/// `images` guarda como maximo tres rutas: en esta fase son assets o rutas
/// locales del selector de imagenes; al conectar Roble seran URLs.
class CarListing {
  const CarListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    required this.mileageKm,
    required this.fuel,
    required this.transmission,
    required this.city,
    required this.description,
    required this.images,
    required this.status,
    required this.createdAt,
    this.buyerId,
    this.buyerName,
    this.soldAt,
  });

  static const int maxImages = 3;

  final String id;
  final String sellerId;
  final String sellerName;
  final String brand;
  final String model;
  final int year;
  final double price;
  final int mileageKm;
  final FuelType fuel;
  final TransmissionType transmission;
  final String city;
  final String description;
  final List<String> images;
  final ListingStatus status;
  final DateTime createdAt;

  /// Quien compro, cuando la venta quedo registrada. Es lo que convierte una
  /// publicacion vendida en una linea del historial de compras de alguien, y
  /// lo que habilita que las dos partes se califiquen.
  final String? buyerId;
  final String? buyerName;
  final DateTime? soldAt;

  /// Una venta registrada: vendida **y** con comprador. Marcar «Vendido» sin
  /// decir a quien deja la publicacion cerrada pero sin contraparte.
  bool get hasRegisteredSale =>
      status == ListingStatus.sold && (buyerId?.isNotEmpty ?? false);

  String get title => '$brand $model $year';

  /// La imagen de portada, o `null` si la publicacion no tiene fotos.
  String? get cover => images.isEmpty ? null : images.first;

  CarListing copyWith({
    String? brand,
    String? model,
    int? year,
    double? price,
    int? mileageKm,
    FuelType? fuel,
    TransmissionType? transmission,
    String? city,
    String? description,
    List<String>? images,
    ListingStatus? status,
    String? buyerId,
    String? buyerName,
    DateTime? soldAt,
  }) {
    return CarListing(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      price: price ?? this.price,
      mileageKm: mileageKm ?? this.mileageKm,
      fuel: fuel ?? this.fuel,
      transmission: transmission ?? this.transmission,
      city: city ?? this.city,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      soldAt: soldAt ?? this.soldAt,
    );
  }
}
