import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/data/listings_repository.dart';

enum MapFilterPill { all, forSale, land, rental }

enum TerravaMapStyle { streets, satellite }

class MapLatLng {
  const MapLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

List<MapListingPin> pinsForPill(List<MapListingPin> pins, MapFilterPill pill) {
  switch (pill) {
    case MapFilterPill.all:
      return pins;
    case MapFilterPill.forSale:
      return pins.where((p) => p.transactionType == 'SALE').toList();
    case MapFilterPill.land:
      return pins.where((p) => p.propertyType == 'LAND').toList();
    case MapFilterPill.rental:
      return pins
          .where(
            (p) => p.transactionType == 'RENT' || p.transactionType == 'LEASE',
          )
          .toList();
  }
}

class MapDiscoveryState {
  const MapDiscoveryState({
    this.bounds,
    this.filters = ListingFilters.empty,
    this.pill = MapFilterPill.all,
    this.allPins = const [],
    this.selectedListingId,
    this.selectedDetail,
    this.isLoadingPins = false,
    this.isLoadingDetail = false,
    this.isSearching = false,
    this.pinsError,
    this.detailError,
    this.searchError,
    this.searchQuery = '',
    this.mapStyle = TerravaMapStyle.streets,
    this.cameraTarget,
  });

  final MapBounds? bounds;
  final ListingFilters filters;
  final MapFilterPill pill;
  final List<MapListingPin> allPins;
  final String? selectedListingId;
  final ListingDetail? selectedDetail;
  final bool isLoadingPins;
  final bool isLoadingDetail;
  final bool isSearching;
  final String? pinsError;
  final String? detailError;
  final String? searchError;
  final String searchQuery;
  final TerravaMapStyle mapStyle;
  final MapLatLng? cameraTarget;

  List<MapListingPin> get pins => pinsForPill(allPins, pill);

  int countFor(MapFilterPill value) => pinsForPill(allPins, value).length;

  MapDiscoveryState copyWith({
    MapBounds? bounds,
    ListingFilters? filters,
    MapFilterPill? pill,
    List<MapListingPin>? allPins,
    String? selectedListingId,
    ListingDetail? selectedDetail,
    bool? isLoadingPins,
    bool? isLoadingDetail,
    bool? isSearching,
    String? pinsError,
    String? detailError,
    String? searchError,
    String? searchQuery,
    TerravaMapStyle? mapStyle,
    MapLatLng? cameraTarget,
    bool clearSelected = false,
    bool clearPinsError = false,
    bool clearDetailError = false,
    bool clearSearchError = false,
    bool clearDetail = false,
  }) {
    return MapDiscoveryState(
      bounds: bounds ?? this.bounds,
      filters: filters ?? this.filters,
      pill: pill ?? this.pill,
      allPins: allPins ?? this.allPins,
      selectedListingId: clearSelected
          ? null
          : (selectedListingId ?? this.selectedListingId),
      selectedDetail: clearSelected || clearDetail
          ? null
          : (selectedDetail ?? this.selectedDetail),
      isLoadingPins: isLoadingPins ?? this.isLoadingPins,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isSearching: isSearching ?? this.isSearching,
      pinsError: clearPinsError ? null : (pinsError ?? this.pinsError),
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      searchQuery: searchQuery ?? this.searchQuery,
      mapStyle: mapStyle ?? this.mapStyle,
      cameraTarget: cameraTarget ?? this.cameraTarget,
    );
  }
}

class MapDiscoveryController extends Notifier<MapDiscoveryState> {
  CancelToken? _pinsToken;
  CancelToken? _detailToken;
  MapBounds? _lastFetchedBounds;
  ListingFilters? _lastFetchedFilters;

  @override
  MapDiscoveryState build() => const MapDiscoveryState();

  void setCameraTarget(MapLatLng target) {
    state = state.copyWith(cameraTarget: target);
  }

  void toggleMapType() {
    state = state.copyWith(
      mapStyle: state.mapStyle == TerravaMapStyle.streets
          ? TerravaMapStyle.satellite
          : TerravaMapStyle.streets,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> onBoundsChanged(MapBounds bounds) async {
    state = state.copyWith(bounds: bounds);
    await _fetchPinsIfNeeded(bounds: bounds, filters: state.filters);
  }

  void selectPill(MapFilterPill pill) {
    final next = state.copyWith(pill: pill);
    final stillVisible = next.pins.any((p) => p.id == state.selectedListingId);
    state = next.copyWith(clearSelected: !stillVisible);
  }

  Future<void> applyAdvancedFilters({
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    double? bathrooms,
  }) async {
    final filters = ListingFilters(
      minPrice: minPrice,
      maxPrice: maxPrice,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      q: state.filters.q,
    );
    state = state.copyWith(filters: filters);
    final bounds = state.bounds;
    if (bounds != null) {
      await _fetchPinsIfNeeded(bounds: bounds, filters: filters, force: true);
    }
  }

  Future<List<MapListingPin>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(
        searchError: 'Enter a city, neighborhood, or property name.',
      );
      return const [];
    }

    state = state.copyWith(
      isSearching: true,
      searchQuery: q,
      clearSearchError: true,
    );

    try {
      final results = await ref
          .read(listingsRepositoryProvider)
          .search(q: q, bounds: state.bounds, filters: state.filters);
      state = state.copyWith(
        isSearching: false,
        allPins: results,
        searchError: results.isEmpty
            ? 'No listings matched your search.'
            : null,
      );
      return pinsForPill(results, state.pill);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        searchError: e is ApiException ? e.message : 'Search failed.',
      );
      return const [];
    }
  }

  Future<void> selectListing(String id) async {
    _detailToken?.cancel();
    _detailToken = CancelToken();

    state = state.copyWith(
      selectedListingId: id,
      isLoadingDetail: true,
      clearDetailError: true,
      clearDetail: true,
    );

    try {
      final detail = await ref
          .read(listingsRepositoryProvider)
          .fetchListingDetail(id);
      if (state.selectedListingId != id) return;
      state = state.copyWith(selectedDetail: detail, isLoadingDetail: false);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      state = state.copyWith(
        isLoadingDetail: false,
        detailError: e is ApiException ? e.message : 'Failed to load listing.',
      );
    }
  }

  void clearSelection() {
    _detailToken?.cancel();
    state = state.copyWith(clearSelected: true);
  }

  Future<void> _fetchPinsIfNeeded({
    required MapBounds bounds,
    required ListingFilters filters,
    bool force = false,
  }) async {
    if (!force &&
        _lastFetchedBounds == bounds &&
        _lastFetchedFilters == filters) {
      return;
    }

    _pinsToken?.cancel();
    _pinsToken = CancelToken();
    state = state.copyWith(isLoadingPins: true, clearPinsError: true);

    try {
      final pins = await ref
          .read(listingsRepositoryProvider)
          .fetchMapPins(
            bounds: bounds,
            filters: filters,
            cancelToken: _pinsToken,
          );
      _lastFetchedBounds = bounds;
      _lastFetchedFilters = filters;
      final next = state.copyWith(allPins: pins, isLoadingPins: false);
      final stillVisible = next.pins.any(
        (p) => p.id == state.selectedListingId,
      );
      state = next.copyWith(clearSelected: !stillVisible);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      state = state.copyWith(
        isLoadingPins: false,
        pinsError: e is ApiException ? e.message : 'Failed to load listings.',
      );
    }
  }
}

final mapDiscoveryControllerProvider =
    NotifierProvider<MapDiscoveryController, MapDiscoveryState>(
      MapDiscoveryController.new,
    );
