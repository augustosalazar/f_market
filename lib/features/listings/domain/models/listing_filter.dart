/// Los filtros del catalogo. Se pasan al repositorio para que la busqueda
/// pueda resolverse en el servidor cuando se conecte Roble.
class ListingFilter {
  const ListingFilter({
    this.query = '',
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.minYear,
  });

  final String query;
  final String? brand;
  final double? minPrice;
  final double? maxPrice;
  final int? minYear;

  bool get isEmpty =>
      query.isEmpty &&
      brand == null &&
      minPrice == null &&
      maxPrice == null &&
      minYear == null;

  ListingFilter copyWith({
    String? query,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
    bool clearBrand = false,
    bool clearPrice = false,
    bool clearYear = false,
  }) => ListingFilter(
    query: query ?? this.query,
    brand: clearBrand ? null : (brand ?? this.brand),
    minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
    maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
    minYear: clearYear ? null : (minYear ?? this.minYear),
  );
}
