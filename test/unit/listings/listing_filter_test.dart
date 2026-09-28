import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';

/// Dominio puro: entra un valor, sale otro. No hace falta nada falso.
void main() {
  test('un filtro nuevo esta vacio', () {
    const filtro = ListingFilter();

    expect(filtro.isEmpty, isTrue);
  });

  test('con texto de busqueda ya no esta vacio', () {
    const filtro = ListingFilter(query: 'mazda');

    expect(filtro.isEmpty, isFalse);
  });

  test('copyWith cambia solo lo que se le pasa', () {
    const filtro = ListingFilter(query: 'mazda', minYear: 2020);

    final nuevo = filtro.copyWith(brand: 'Kia');

    expect(nuevo.brand, 'Kia');
    expect(nuevo.query, 'mazda');
    expect(nuevo.minYear, 2020);
  });

  test('clearBrand quita la marca', () {
    // Pasar `brand: null` no la quitaria: `copyWith` lo lee como «no la
    // toques». Por eso existen los `clear...`.
    const filtro = ListingFilter(brand: 'Kia');

    final nuevo = filtro.copyWith(clearBrand: true);

    expect(nuevo.brand, isNull);
    expect(nuevo.isEmpty, isTrue);
  });
}
