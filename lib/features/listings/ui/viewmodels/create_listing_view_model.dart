import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';

/// El formulario de publicacion: guarda lo que se escribe y valida antes de
/// mandarlo al repositorio, para que la vista sea solo campos.
class CreateListingViewModel extends GetxController {
  CreateListingViewModel(this._listings, this._session);

  final IListingRepository _listings;
  final SessionViewModel _session;

  final brand = ''.obs;
  final model = ''.obs;
  final year = ''.obs;
  final price = ''.obs;
  final mileage = ''.obs;
  final city = ''.obs;
  final description = ''.obs;
  final fuel = FuelType.gasoline.obs;
  final transmission = TransmissionType.manual.obs;

  /// Rutas locales de las fotos elegidas. Como maximo tres (requisito 4).
  final images = <String>[].obs;
  final saving = false.obs;
  final error = RxnString();

  bool get canAddPhoto => images.length < CarListing.maxImages;

  Future<void> pickPhoto(ImageSource source) async {
    if (!canAddPhoto) {
      error.value = 'Ya tienes el maximo de ${CarListing.maxImages} fotos.';
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) images.add(picked.path);
    } catch (_) {
      error.value = 'No se pudo abrir la camara o la galeria en este equipo.';
    }
  }

  void removePhoto(String path) => images.remove(path);

  /// Devuelve la publicacion creada, o `null` si la validacion fallo.
  Future<CarListing?> submit() async {
    error.value = null;
    final parsedYear = int.tryParse(year.value.trim()) ?? 0;
    final parsedPrice =
        double.tryParse(price.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final parsedMileage =
        int.tryParse(mileage.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final currentYear = DateTime.now().year;

    if (brand.value.trim().isEmpty) return _fail('Indica la marca.');
    if (model.value.trim().isEmpty) return _fail('Indica el modelo.');
    if (parsedYear < 1900 || parsedYear > currentYear + 1) {
      return _fail('El ano debe estar entre 1900 y ${currentYear + 1}.');
    }
    if (parsedPrice <= 0) return _fail('El precio debe ser mayor que cero.');
    if (parsedMileage < 0) return _fail('El kilometraje no puede ser negativo.');
    if (images.isEmpty) return _fail('Sube al menos una foto.');
    if (images.length > CarListing.maxImages) {
      return _fail('Maximo ${CarListing.maxImages} fotos.');
    }

    saving.value = true;
    try {
      final seller = _session.requireUser;
      return await _listings.create(
        CarListing(
          id: '',
          sellerId: seller.userId,
          sellerName: seller.name,
          brand: brand.value.trim(),
          model: model.value.trim(),
          year: parsedYear,
          price: parsedPrice,
          mileageKm: parsedMileage,
          fuel: fuel.value,
          transmission: transmission.value,
          city: city.value.trim(),
          description: description.value.trim(),
          images: List.of(images),
          status: ListingStatus.available,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      return _fail('No se pudo publicar. Intenta de nuevo.');
    } finally {
      saving.value = false;
    }
  }

  CarListing? _fail(String message) {
    error.value = message;
    return null;
  }
}
