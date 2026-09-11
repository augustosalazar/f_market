import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/create_listing_view_model.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_model.dart';

/// Publicar un carro: caracteristicas basicas y hasta tres fotos
/// (requisito 4). Solo se llega aqui con sesion iniciada.
class CreateListingPage extends GetView<CreateListingViewModel> {
  const CreateListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar carro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sin almacenamiento no hay donde subir una foto, asi que el
          // formulario no lo ofrece en vez de aceptar algo que se perderia.
          // Cuando lo haya, vuelve aqui el selector: el modelo, las columnas
          // `image_1..3` y `CarPhoto` ya lo esperan.
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Todavia no se pueden subir fotos'),
              subtitle: Text(
                'Tu publicacion se vera con un color de fondo. Las fotos llegan '
                'cuando se habilite el almacenamiento.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => DropdownButtonFormField<CarBrand>(
              initialValue: controller.brand.value,
              decoration: const InputDecoration(labelText: 'Marca'),
              items: [
                for (final brand in controller.brands)
                  DropdownMenuItem(value: brand, child: Text(brand.name)),
              ],
              onChanged: controller.selectBrand,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<CarModel>(
              initialValue: controller.model.value,
              decoration: InputDecoration(
                labelText: 'Modelo',
                // Sin marca no hay modelos que ofrecer, y decirlo es mejor que
                // una lista vacia que parece rota.
                helperText: controller.brand.value == null
                    ? 'Elige primero la marca'
                    : null,
              ),
              items: [
                for (final model in controller.models)
                  DropdownMenuItem(value: model, child: Text(model.name)),
              ],
              onChanged: controller.models.isEmpty
                  ? null
                  : controller.selectModel,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Ano',
                  keyboard: TextInputType.number,
                  onChanged: (v) => controller.year.value = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: 'Kilometraje',
                  keyboard: TextInputType.number,
                  onChanged: (v) => controller.mileage.value = v,
                ),
              ),
            ],
          ),
          _Field(
            label: 'Precio',
            keyboard: TextInputType.number,
            onChanged: (v) => controller.price.value = v,
          ),
          _Field(label: 'Ciudad', onChanged: (v) => controller.city.value = v),
          const SizedBox(height: 4),
          Text('Combustible', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                for (final fuel in FuelType.values)
                  ChoiceChip(
                    label: Text(fuel.label),
                    selected: controller.fuel.value == fuel,
                    onSelected: (_) => controller.fuel.value = fuel,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Transmision', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                for (final t in TransmissionType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: controller.transmission.value == t,
                    onSelected: (_) => controller.transmission.value = t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Descripcion',
            maxLines: 4,
            onChanged: (v) => controller.description.value = v,
          ),
          const SizedBox(height: 8),
          Obx(() {
            final error = controller.error.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }),
          Obx(
            () => FilledButton(
              onPressed: controller.saving.value
                  ? null
                  : () async {
                      final created = await controller.submit();
                      if (created != null) Get.back(result: created);
                    },
              child: controller.saving.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publicar'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.onChanged,
    this.keyboard,
    this.maxLines = 1,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        keyboardType: keyboard,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
