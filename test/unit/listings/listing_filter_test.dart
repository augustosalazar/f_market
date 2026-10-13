import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';

/// Dominio puro: entra un valor, sale otro. No hace falta nada falso.
void main() {
  test('un filtro nuevo esta vacio', () {
    const filter = ListingFilter();

    expect(filter.isEmpty, isTrue);
  });

  test('con texto de busqueda ya no esta vacio', () {
    const filter = ListingFilter(query: 'mazda');

    expect(filter.isEmpty, isFalse);
  });

  test('copyWith cambia solo lo que se le pasa', () {
    const filter = ListingFilter(query: 'mazda', minYear: 2020);

    final updated = filter.copyWith(brand: 'Kia');

    expect(updated.brand, 'Kia');
    expect(updated.query, 'mazda');
    expect(updated.minYear, 2020);
  });

  test('clearBrand quita la marca', () {
    // Pasar `brand: null` no la quitaria: `copyWith` lo lee como «no la
    // toques». Por eso existen los `clear...`.
    const filter = ListingFilter(brand: 'Kia');

    final updated = filter.copyWith(clearBrand: true);

    expect(updated.brand, isNull);
    expect(updated.isEmpty, isTrue);
  });
}
