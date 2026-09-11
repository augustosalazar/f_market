import 'package:flutter/material.dart';

import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';

/// La tira horizontal de marcas del catalogo.
///
/// Es un filtro de un toque, no un sustituto de la hoja de filtros: por eso
/// solo lleva marca. Lo demas —precio, ano— sigue donde estaba, porque son
/// rangos y no caben en un chip.
class BrandStrip extends StatelessWidget {
  const BrandStrip({
    super.key,
    required this.brands,
    required this.selected,
    required this.onSelected,
  });

  final List<CarBrand> brands;

  /// El nombre de la marca elegida, o `null` para «Todas».
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Una mas que las marcas: la primera es «Todas», que es como se quita
        // el filtro sin ir a buscarlo a la hoja.
        itemCount: brands.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('Todas'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final brand = brands[index - 1];
          return ChoiceChip(
            label: Text(brand.name),
            selected: selected == brand.name,
            // Volver a tocar la marca elegida la quita: es lo que espera quien
            // usa la tira para ir saltando de marca en marca.
            onSelected: (isSelected) =>
                onSelected(isSelected ? brand.name : null),
          );
        },
      ),
    );
  }
}
