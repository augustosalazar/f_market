/// Un modelo del catalogo, colgado de su marca.
class CarModel {
  const CarModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String brandId;
  final String name;
  final int sortOrder;
}
