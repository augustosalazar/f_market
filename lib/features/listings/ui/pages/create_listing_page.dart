import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/create_listing_view_model.dart';

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
          Text('Fotos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Hasta ${CarListing.maxImages}. La primera es la portada.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          // Las observables se leen dentro del propio Obx: si solo se leen
          // dentro del hijo, GetX no ve ninguna y lanza «improper use».
          Obx(
            () => _PhotoStrip(
              images: controller.images.toList(),
              canAddPhoto: controller.canAddPhoto,
              onRemove: controller.removePhoto,
              onPick: controller.pickPhoto,
            ),
          ),
          const SizedBox(height: 24),
          _Field(label: 'Marca', onChanged: (v) => controller.brand.value = v),
          _Field(label: 'Modelo', onChanged: (v) => controller.model.value = v),
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

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.images,
    required this.canAddPhoto,
    required this.onRemove,
    required this.onPick,
  });

  final List<String> images;
  final bool canAddPhoto;
  final void Function(String path) onRemove;
  final void Function(ImageSource source) onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final path in images)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(path),
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 104,
                        height: 104,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton.filledTonal(
                      iconSize: 16,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onRemove(path),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          if (canAddPhoto) _AddPhotoButton(onPick: onPick),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onPick});

  final void Function(ImageSource source) onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPick(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined),
            SizedBox(height: 6),
            Text('Agregar'),
          ],
        ),
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
