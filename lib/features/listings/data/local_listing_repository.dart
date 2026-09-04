import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/core/data/dummy_data.dart';

class LocalListingRepository implements IListingRepository {
  LocalListingRepository(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 400);

  @override
  Future<List<CarListing>> search(ListingFilter filter) async {
    await Future.delayed(_delay);
    final q = filter.query.trim().toLowerCase();
    final result = _data.listings.where((l) {
      if (q.isNotEmpty &&
          !'${l.brand} ${l.model} ${l.year} ${l.city}'
              .toLowerCase()
              .contains(q)) {
        return false;
      }
      if (filter.brand != null && l.brand != filter.brand) return false;
      if (filter.minPrice != null && l.price < filter.minPrice!) return false;
      if (filter.maxPrice != null && l.price > filter.maxPrice!) return false;
      if (filter.minYear != null && l.year < filter.minYear!) return false;
      return true;
    }).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<CarListing?> byId(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _data.listings.where((l) => l.id == id).firstOrNull;
  }

  @override
  Future<List<CarListing>> bySeller(String sellerId) async {
    await Future.delayed(_delay);
    final result =
        _data.listings.where((l) => l.sellerId == sellerId).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<CarListing> create(CarListing listing) async {
    await Future.delayed(_delay);
    final stored = CarListing(
      id: _data.nextId('l'),
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      brand: listing.brand,
      model: listing.model,
      year: listing.year,
      price: listing.price,
      mileageKm: listing.mileageKm,
      fuel: listing.fuel,
      transmission: listing.transmission,
      city: listing.city,
      description: listing.description,
      images: List.unmodifiable(listing.images),
      status: listing.status,
      createdAt: listing.createdAt,
    );
    _data.listings.insert(0, stored);
    return stored;
  }

  @override
  Future<CarListing> changeStatus(String listingId, ListingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _data.listings.indexWhere((l) => l.id == listingId);
    if (index < 0) throw StateError('No existe la publicacion $listingId');
    final updated = _data.listings[index].copyWith(status: status);
    _data.listings[index] = updated;
    return updated;
  }

  @override
  Future<List<CarListing>> followedBy(String userId) async {
    await Future.delayed(_delay);
    final ids = await followedIds(userId);
    return _data.listings.where((l) => ids.contains(l.id)).toList();
  }

  @override
  Future<Set<String>> followedIds(String userId) async {
    return _data.followers.entries
        .where((e) => e.value.contains(userId))
        .map((e) => e.key)
        .toSet();
  }

  @override
  Future<bool> toggleFollow({
    required String listingId,
    required String userId,
  }) async {
    final set = _data.followers.putIfAbsent(listingId, () => <String>{});
    if (set.remove(userId)) return false;
    set.add(userId);
    return true;
  }

  @override
  Future<List<String>> followerIdsOf(String listingId) async =>
      (_data.followers[listingId] ?? const <String>{}).toList();

  @override
  Future<List<String>> brands() async {
    final brands = _data.listings.map((l) => l.brand).toSet().toList()..sort();
    return brands;
  }
}
