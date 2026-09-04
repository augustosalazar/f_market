import 'package:flutter/material.dart';

import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';

/// Hoja de filtros del catalogo. Devuelve el filtro nuevo, o `null` si se
/// cierra sin aplicar.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.initial, required this.brands});

  final ListingFilter initial;
  final List<String> brands;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _brand = widget.initial.brand;
  late final _minPrice = TextEditingController(
    text: widget.initial.minPrice?.toStringAsFixed(0) ?? '',
  );
  late final _maxPrice = TextEditingController(
    text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '',
  );
  late final _minYear = TextEditingController(
    text: widget.initial.minYear?.toString() ?? '',
  );

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    _minYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtrar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _brand == null,
                onSelected: (_) => setState(() => _brand = null),
              ),
              for (final brand in widget.brands)
                ChoiceChip(
                  label: Text(brand),
                  selected: _brand == brand,
                  onSelected: (_) => setState(() => _brand = brand),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio desde'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio hasta'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minYear,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ano desde'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, const ListingFilter()),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ListingFilter(
                      query: widget.initial.query,
                      brand: _brand,
                      minPrice: double.tryParse(_minPrice.text),
                      maxPrice: double.tryParse(_maxPrice.text),
                      minYear: int.tryParse(_minYear.text),
                    ),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
