/// Una marca del catalogo precargado.
///
/// El catalogo es cerrado a proposito: si cada quien escribe la marca a mano,
/// «Chevrolet», «chevrolet» y «Chevrolett» son tres marcas distintas y el
/// filtro deja de servir.
class CarBrand {
  const CarBrand({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;

  /// El orden en que se muestran. Las mas vendidas primero, que es lo que
  /// hace util una tira horizontal: lo probable queda a la vista sin arrastrar.
  final int sortOrder;
}
