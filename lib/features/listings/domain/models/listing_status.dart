/// Estado de una publicacion. Un cambio de estado notifica a los seguidores.
enum ListingStatus {
  available('Disponible'),
  reserved('Reservado'),
  sold('Vendido'),
  withdrawn('Retirado');

  const ListingStatus(this.label);
  final String label;

  static ListingStatus fromName(String name) => ListingStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => ListingStatus.available,
  );
}
