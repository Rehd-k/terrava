import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:terrava/core/config/app_config.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/presentation/create/create_listing_entry.dart';
import 'package:terrava/features/listings/presentation/listing_beacon.dart';
import 'package:terrava/features/listings/presentation/listing_detail_view.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';
import 'package:terrava/features/map/providers/location_provider.dart';
import 'package:terrava/features/map/providers/map_listings_provider.dart';
import 'package:terrava/features/saved/presentation/save_listing_button.dart';

@RoutePage()
class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({super.key});

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;
  Cancelable? _annotationTapCancelable;
  CameraViewportState? _initialViewport;
  CameraOptions? _initialCamera;
  final _searchController = TextEditingController();
  final _sheetController = DraggableScrollableController();
  final _markerCache = <String, Uint8List>{};
  final _annotationListingIds = <String, String>{};
  bool _sheetExpanded = false;
  bool _hasCenteredOnUser = false;
  bool _ignoreNextMapTap = false;
  Timer? _boundsDebounce;
  int _markerGeneration = 0;

  static const _fallback = MapLatLng(5.0377, 7.9128);
  static const _streetZoom = 16.5;
  static final _animation = MapAnimationOptions(duration: 800);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _boundsDebounce?.cancel();
    _annotationTapCancelable?.cancel();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final discovery = ref.watch(mapDiscoveryControllerProvider);

    ref.listen(mapDiscoveryControllerProvider.select((s) => s.pins), (_, pins) {
      final selectedId = ref
          .read(mapDiscoveryControllerProvider)
          .selectedListingId;
      _rebuildMarkers(pins, selectedId);
    });

    ref.listen(
      mapDiscoveryControllerProvider.select((s) => s.selectedListingId),
      (_, id) {
        final pins = ref.read(mapDiscoveryControllerProvider).pins;
        _rebuildMarkers(pins, id);
      },
    );

    ref.listen(mapDiscoveryControllerProvider.select((s) => s.mapStyle), (
      previous,
      style,
    ) {
      if (previous == style) return;
      _mapboxMap?.loadStyleURI(_styleUri(style));
    });

    ref.listen(
      locationControllerProvider.select((s) => s.permission),
      (_, permission) => _syncLocationPuck(permission),
    );

    ref.listen(locationControllerProvider.select((s) => s.position), (
      _,
      position,
    ) {
      if (position == null || _hasCenteredOnUser) return;
      _centerCameraOnUser();
    });

    final initialTarget = location.position != null
        ? MapLatLng(location.position!.latitude, location.position!.longitude)
        : _fallback;

    return Scaffold(
      backgroundColor: TerravaColors.mapCanvas,
      body: Stack(
        children: [
          _buildMap(initialTarget, discovery.mapStyle),
          if (discovery.selectedListingId != null) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSheet,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Color(0x1A000000)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.46,
                minChildSize: 0.22,
                maxChildSize: 0.94,
                snap: true,
                snapSizes: const [0.46, 0.94],
                builder: (context, scrollController) {
                  return NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      final expanded = notification.extent > 0.7;
                      if (expanded != _sheetExpanded && mounted) {
                        setState(() => _sheetExpanded = expanded);
                      }
                      if (notification.extent < 0.30) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _closeSheet();
                        });
                      }
                      return false;
                    },
                    child: _PropertyBottomSheet(
                      discovery: discovery,
                      expanded: _sheetExpanded,
                      scrollController: scrollController,
                      onToggleExpand: () {
                        if (_sheetExpanded) {
                          _collapseSheet();
                        } else {
                          _expandSheet();
                        }
                      },
                      onClose: _closeSheet,
                      onContact: () {
                        final detail = discovery.selectedDetail;
                        if (detail == null) return;
                        openListingInquiry(context, ref, detail);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onLocate: _recenterToUser,
                    onFilter: _openFilters,
                    onSubmit: _runSearch,
                  ),
                  const SizedBox(height: 8),
                  _FilterPills(
                    active: discovery.pill,
                    allCount: discovery.countFor(MapFilterPill.all),
                    saleCount: discovery.countFor(MapFilterPill.forSale),
                    landCount: discovery.countFor(MapFilterPill.land),
                    rentalCount: discovery.countFor(MapFilterPill.rental),
                    onSelected: (pill) {
                      final notifier = ref.read(
                        mapDiscoveryControllerProvider.notifier,
                      );
                      if (pill == discovery.pill && pill != MapFilterPill.all) {
                        notifier.selectPill(MapFilterPill.all);
                      } else {
                        notifier.selectPill(pill);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: MediaQuery.paddingOf(context).top + 120,
            child: Column(
              children: [
                _HudButton(
                  icon: Icons.navigation,
                  color: TerravaColors.error,
                  onTap: () async {
                    await _flyTo(
                      lat:
                          discovery.cameraTarget?.latitude ??
                          initialTarget.latitude,
                      lng:
                          discovery.cameraTarget?.longitude ??
                          initialTarget.longitude,
                      zoom: _streetZoom,
                      bearing: 0,
                      pitch: 0,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _HudButton(
                  icon: Icons.layers_outlined,
                  onTap: () => ref
                      .read(mapDiscoveryControllerProvider.notifier)
                      .toggleMapType(),
                ),
                const SizedBox(height: 8),
                const _HudButton(icon: Icons.polyline_outlined),
                const SizedBox(height: 8),
                _HudButton(
                  icon: Icons.add,
                  color: TerravaColors.primary,
                  onTap: () => openCreateListing(context, ref),
                ),
              ],
            ),
          ),
          if (discovery.cameraTarget != null)
            Positioned(
              left: 16,
              bottom: discovery.selectedListingId != null ? 340 : 110,
              child: _CoordinateChip(target: discovery.cameraTarget!),
            ),
          if (discovery.isLoadingPins || discovery.isSearching)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (location.errorMessage != null &&
              location.permission != LocationPermissionStatus.granted)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: _StatusBanner(
                message: location.errorMessage!,
                actionLabel: 'Retry',
                onAction: () =>
                    ref.read(locationControllerProvider.notifier).initialize(),
              ),
            ),
          if (discovery.pinsError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: _StatusBanner(
                message: discovery.pinsError!,
                actionLabel: 'Retry',
                onAction: _publishBounds,
              ),
            ),
          if (discovery.searchError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: _StatusBanner(message: discovery.searchError!),
            ),
          if (!discovery.isLoadingPins &&
              discovery.pins.isEmpty &&
              discovery.bounds != null &&
              discovery.pinsError == null &&
              discovery.searchError == null)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: _StatusBanner(
                message: 'No approved listings in this map area.',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(MapLatLng initialTarget, TerravaMapStyle mapStyle) {
    if (kIsWeb) {
      return const ColoredBox(
        color: TerravaColors.mapCanvas,
        child: Center(child: Text('Maps are available on iOS and Android.')),
      );
    }

    if (AppConfig.mapboxAccessToken.isEmpty) {
      return const ColoredBox(
        color: TerravaColors.mapCanvas,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Mapbox token missing.\n\nStop the app and run:\nflutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.YOUR_TOKEN',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    _initialCamera ??= CameraOptions(
      center: _toPoint(initialTarget.latitude, initialTarget.longitude),
      zoom: _streetZoom,
      bearing: 0,
      pitch: 0,
    );
    _initialViewport ??= CameraViewportState(
      center: _toPoint(initialTarget.latitude, initialTarget.longitude),
      zoom: _streetZoom,
      bearing: 0,
      pitch: 0,
    );

    return MapWidget(
      key: const ValueKey('terrava-map'),
      styleUri: _styleUri(mapStyle),
      // Native map creation still reads cameraOptions; viewport alone can
      // leave the camera at the default world view until the view is sized.
      // ignore: deprecated_member_use
      cameraOptions: _initialCamera,
      viewport: _initialViewport,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: (_) => _onStyleLoaded(),
      onMapLoadedListener: (_) {
        if (!_hasCenteredOnUser) {
          _centerCameraOnUser(animate: false);
        }
      },
      onCameraChangeListener: (event) {
        final coords = event.cameraState.center.coordinates;
        ref
            .read(mapDiscoveryControllerProvider.notifier)
            .setCameraTarget(
              MapLatLng(coords.lat.toDouble(), coords.lng.toDouble()),
            );
      },
      onMapIdleListener: (_) {
        _boundsDebounce?.cancel();
        _boundsDebounce = Timer(const Duration(milliseconds: 400), () {
          _publishBounds();
        });
      },
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await _syncLocationPuck(ref.read(locationControllerProvider).permission);
    mapboxMap.addInteraction(
      TapInteraction.onMap((_) {
        if (_ignoreNextMapTap) {
          _ignoreNextMapTap = false;
          return;
        }
        ref.read(mapDiscoveryControllerProvider.notifier).clearSelection();
        if (mounted) setState(() => _sheetExpanded = false);
      }),
      interactionID: 'map-tap-clear-selection',
    );
  }

  Future<void> _onStyleLoaded() async {
    final map = _mapboxMap;
    if (map == null) return;

    _annotationTapCancelable?.cancel();
    _annotationTapCancelable = null;
    final previousManager = _pointManager;
    _pointManager = null;
    if (previousManager != null) {
      await map.annotations.removeAnnotationManager(previousManager);
    }

    _pointManager = await map.annotations.createPointAnnotationManager();
    await _pointManager!.setIconAllowOverlap(true);
    _annotationTapCancelable = _pointManager!.tapEvents(
      onTap: _onAnnotationTap,
    );

    if (!_hasCenteredOnUser) {
      await _centerCameraOnUser(animate: false);
    }

    final discovery = ref.read(mapDiscoveryControllerProvider);
    await _rebuildMarkers(discovery.pins, discovery.selectedListingId);
    await _publishBounds();
  }

  void _onAnnotationTap(PointAnnotation annotation) {
    _ignoreNextMapTap = true;
    final listingId =
        _annotationListingIds[annotation.id] ??
        annotation.customData?['listingId'] as String?;
    if (listingId == null) return;
    setState(() => _sheetExpanded = false);
    _collapseSheet();
    ref.read(mapDiscoveryControllerProvider.notifier).selectListing(listingId);
  }

  Future<void> _collapseSheet() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.46,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _expandSheet() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.94,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeSheet() {
    if (!mounted) return;
    if (ref.read(mapDiscoveryControllerProvider).selectedListingId == null) {
      return;
    }
    ref.read(mapDiscoveryControllerProvider.notifier).clearSelection();
    setState(() => _sheetExpanded = false);
  }

  Future<void> _centerCameraOnUser({bool animate = true}) async {
    final map = _mapboxMap;
    if (map == null) return;

    final position = ref.read(locationControllerProvider).position;
    final options = CameraOptions(
      center: _toPoint(
        position?.latitude ?? _fallback.latitude,
        position?.longitude ?? _fallback.longitude,
      ),
      zoom: _streetZoom,
      bearing: 0,
      pitch: 0,
    );
    if (animate) {
      await map.flyTo(options, _animation);
    } else {
      await map.setCamera(options);
    }
    if (position != null) {
      _hasCenteredOnUser = true;
    }
  }

  Future<void> _syncLocationPuck(LocationPermissionStatus permission) async {
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: permission == LocationPermissionStatus.granted,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );
  }

  String _styleUri(TerravaMapStyle style) {
    return style == TerravaMapStyle.satellite
        ? MapboxStyles.STANDARD_SATELLITE
        : MapboxStyles.STANDARD;
  }

  Point _toPoint(double lat, double lng) {
    return Point(coordinates: Position(lng, lat));
  }

  Future<void> _flyTo({
    required double lat,
    required double lng,
    double zoom = _streetZoom,
    double bearing = 0,
    double pitch = 0,
  }) async {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: _toPoint(lat, lng),
        zoom: zoom,
        bearing: bearing,
        pitch: pitch,
      ),
      _animation,
    );
  }

  Future<void> _publishBounds() async {
    final map = _mapboxMap;
    if (map == null) return;
    final camera = await map.getCameraState();
    final bounds = await map.coordinateBoundsForCamera(
      CameraOptions(
        center: camera.center,
        padding: camera.padding,
        zoom: camera.zoom,
        bearing: camera.bearing,
        pitch: camera.pitch,
      ),
    );
    final sw = bounds.southwest.coordinates;
    final ne = bounds.northeast.coordinates;
    final mapBounds = MapBounds(
      minLat: math.min(sw.lat.toDouble(), ne.lat.toDouble()),
      maxLat: math.max(sw.lat.toDouble(), ne.lat.toDouble()),
      minLng: math.min(sw.lng.toDouble(), ne.lng.toDouble()),
      maxLng: math.max(sw.lng.toDouble(), ne.lng.toDouble()),
    );
    await ref
        .read(mapDiscoveryControllerProvider.notifier)
        .onBoundsChanged(mapBounds);
  }

  Future<void> _recenterToUser() async {
    await ref.read(locationControllerProvider.notifier).initialize();
    final position = ref.read(locationControllerProvider).position;
    if (position == null) return;
    _hasCenteredOnUser = true;
    await _flyTo(
      lat: position.latitude,
      lng: position.longitude,
      zoom: _streetZoom,
    );
  }

  Future<void> _runSearch(String query) async {
    final results = await ref
        .read(mapDiscoveryControllerProvider.notifier)
        .search(query);
    if (results.isEmpty || _mapboxMap == null) return;

    if (results.length == 1) {
      await _flyTo(
        lat: results.first.latitude,
        lng: results.first.longitude,
        zoom: 14,
      );
      return;
    }

    var minLat = results.first.latitude;
    var maxLat = results.first.latitude;
    var minLng = results.first.longitude;
    var maxLng = results.first.longitude;
    for (final pin in results.skip(1)) {
      minLat = math.min(minLat, pin.latitude);
      maxLat = math.max(maxLat, pin.latitude);
      minLng = math.min(minLng, pin.longitude);
      maxLng = math.max(maxLng, pin.longitude);
    }

    final camera = await _mapboxMap!.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: _toPoint(minLat, minLng),
        northeast: _toPoint(maxLat, maxLng),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(top: 72, left: 72, bottom: 72, right: 72),
      null,
      null,
      null,
      null,
    );
    await _mapboxMap!.flyTo(camera, _animation);
  }

  Future<void> _openFilters() async {
    final minPriceController = TextEditingController();
    final maxPriceController = TextEditingController();
    final bedroomsController = TextEditingController();
    final bathroomsController = TextEditingController();

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TerravaColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Refine filters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min bedrooms',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min bathrooms',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );

    if (applied == true) {
      await ref
          .read(mapDiscoveryControllerProvider.notifier)
          .applyAdvancedFilters(
            minPrice: double.tryParse(minPriceController.text),
            maxPrice: double.tryParse(maxPriceController.text),
            bedrooms: int.tryParse(bedroomsController.text),
            bathrooms: double.tryParse(bathroomsController.text),
          );
    }
  }

  Future<void> _rebuildMarkers(
    List<MapListingPin> pins,
    String? selectedId,
  ) async {
    final manager = _pointManager;
    if (manager == null) return;
    final generation = ++_markerGeneration;

    final options = <PointAnnotationOptions>[];
    for (final pin in pins) {
      final selected = pin.id == selectedId;
      final label = formatListingPrice(
        price: pin.price,
        currency: pin.currency,
        transactionType: pin.transactionType,
        pricePeriod: pin.pricePeriod,
        propertyType: pin.propertyType,
        landSize: pin.landSize,
      );
      final cacheKey =
          '${pin.propertyType}_${pin.transactionType}_${label}_$selected';
      var icon = _markerCache[cacheKey];
      icon ??= await createListingBeaconBitmap(
        label: label,
        propertyType: pin.propertyType,
        transactionType: pin.transactionType,
        selected: selected,
      );
      if (generation != _markerGeneration) return;
      _markerCache[cacheKey] = icon;
      options.add(
        PointAnnotationOptions(
          geometry: _toPoint(pin.latitude, pin.longitude),
          image: icon,
          iconAnchor: IconAnchor.BOTTOM,
          symbolSortKey: selected ? 2 : 1,
          customData: {'listingId': pin.id},
        ),
      );
    }

    if (generation != _markerGeneration) return;
    await manager.deleteAll();
    _annotationListingIds.clear();
    if (options.isEmpty) return;

    final created = await manager.createMulti(options);
    if (generation != _markerGeneration) return;
    for (var i = 0; i < created.length && i < pins.length; i++) {
      final annotation = created[i];
      if (annotation == null) continue;
      _annotationListingIds[annotation.id] = pins[i].id;
    }
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onLocate,
    required this.onFilter,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onLocate;
  final VoidCallback onFilter;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLowest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'TERRA',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontSize: 15,
            ),
          ),
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: TerravaColors.outlineVariant,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.search, size: 19, color: TerravaColors.outline),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search parcel, city or sanctuary...',
                hintStyle: TextStyle(
                  color: TerravaColors.outline,
                  fontSize: 13,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          _RoundIconButton(
            icon: Icons.my_location,
            background: TerravaColors.surfaceContainer,
            onTap: onLocate,
          ),
          const SizedBox(width: 4),
          _RoundIconButton(
            icon: Icons.tune,
            background: TerravaColors.primary,
            foreground: TerravaColors.onPrimary,
            onTap: onFilter,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.background,
    this.foreground,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color? foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: foreground ?? TerravaColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({
    required this.active,
    required this.allCount,
    required this.saleCount,
    required this.landCount,
    required this.rentalCount,
    required this.onSelected,
  });

  final MapFilterPill active;
  final int allCount;
  final int saleCount;
  final int landCount;
  final int rentalCount;
  final ValueChanged<MapFilterPill> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            label: 'All ($allCount)',
            selected: active == MapFilterPill.all,
            onTap: () => onSelected(MapFilterPill.all),
            leading: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: TerravaColors.secondaryFixed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          _Pill(
            label: 'For Sale ($saleCount)',
            selected: active == MapFilterPill.forSale,
            onTap: () => onSelected(MapFilterPill.forSale),
            icon: Icons.villa_outlined,
          ),
          _Pill(
            label: 'Land Plots ($landCount)',
            selected: active == MapFilterPill.land,
            onTap: () => onSelected(MapFilterPill.land),
            icon: Icons.landscape_outlined,
          ),
          _Pill(
            label: 'Rental / Lease ($rentalCount)',
            selected: active == MapFilterPill.rental,
            onTap: () => onSelected(MapFilterPill.rental),
            icon: Icons.key_outlined,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? TerravaColors.primary
            : TerravaColors.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: selected
                        ? TerravaColors.onPrimary
                        : TerravaColors.onSurface,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? TerravaColors.onPrimary
                        : TerravaColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.icon, this.onTap, this.color});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: color ?? TerravaColors.onSurface),
        ),
      ),
    );
  }
}

class _CoordinateChip extends StatelessWidget {
  const _CoordinateChip({required this.target});

  final MapLatLng target;

  @override
  Widget build(BuildContext context) {
    final lat = target.latitude.abs().toStringAsFixed(2);
    final lng = target.longitude.abs().toStringAsFixed(2);
    final ns = target.latitude >= 0 ? 'N' : 'S';
    final ew = target.longitude >= 0 ? 'E' : 'W';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLowest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: TerravaColors.secondaryFixedDim,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$lat°$ns, $lng°$ew',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TerravaColors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: TerravaColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _PropertyBottomSheet extends StatelessWidget {
  const _PropertyBottomSheet({
    required this.discovery,
    required this.expanded,
    required this.scrollController,
    required this.onToggleExpand,
    required this.onClose,
    required this.onContact,
  });

  final MapDiscoveryState discovery;
  final bool expanded;
  final ScrollController scrollController;
  final VoidCallback onToggleExpand;
  final VoidCallback onClose;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final detail = discovery.selectedDetail;
    final pin = discovery.pins
        .where((p) => p.id == discovery.selectedListingId)
        .firstOrNull;
    final category = detail == null
        ? (pin == null
              ? 'Loading...'
              : '${transactionLabel(pin.transactionType)} · ${propertyTypeLabel(pin.propertyType)}')
        : '${transactionLabel(detail.transactionType)} · ${propertyTypeLabel(detail.property.type)}';

    final header = _SheetHeader(
      category: category,
      expanded: expanded,
      onToggleExpand: onToggleExpand,
      onClose: onClose,
    );

    return Material(
      color: TerravaColors.surfaceContainerLowest.withValues(alpha: 0.96),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      child: Column(
        children: [
          Expanded(
            child: discovery.isLoadingDetail
                ? ListView(
                    controller: scrollController,
                    children: [
                      header,
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  )
                : discovery.detailError != null
                ? ListView(
                    controller: scrollController,
                    children: [
                      header,
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(discovery.detailError!),
                      ),
                    ],
                  )
                : detail != null && expanded
                ? ListingDetailView(
                    listing: detail,
                    scrollController: scrollController,
                    showChrome: false,
                    header: header,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  )
                : ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      header,
                      if (detail != null) _CompactListingCard(detail: detail),
                    ],
                  ),
          ),
          if (expanded && detail != null)
            ListingContactBar(listing: detail, onContact: onContact),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.category,
    required this.expanded,
    required this.onToggleExpand,
    required this.onClose,
  });

  final String category;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: TerravaColors.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: TerravaColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: TerravaColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToggleExpand,
                child: Row(
                  children: [
                    Text(expanded ? 'Less' : 'Details'),
                    Icon(
                      expanded ? Icons.expand_more : Icons.expand_less,
                      size: 18,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactListingCard extends StatelessWidget {
  const _CompactListingCard({required this.detail});

  final ListingDetail detail;

  @override
  Widget build(BuildContext context) {
    final priceLabel = detail.isRecurring
        ? (detail.transactionType == 'LEASE' ? 'Annual lease' : 'Annual rent')
        : 'Asking price';
    final specs = <Widget>[
      if (detail.property.type != 'LAND' && detail.property.bedrooms != null)
        _MiniSpec(
          icon: Icons.bed_outlined,
          value: '${detail.property.bedrooms} Beds',
        ),
      if (detail.property.type != 'LAND' && detail.property.bathrooms != null)
        _MiniSpec(
          icon: Icons.bathtub_outlined,
          value: '${detail.property.bathrooms} Baths',
        ),
      if (detail.property.propertySize != null)
        _MiniSpec(
          icon: Icons.square_foot,
          value: formatInteriorSize(detail.property.propertySize!),
        ),
      if (detail.property.landSize != null)
        _MiniSpec(
          icon: Icons.landscape_outlined,
          value: formatLandSize(detail.property.landSize!, short: true),
        ),
    ];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 176,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (detail.heroImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: detail.heroImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: TerravaColors.surfaceContainer,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                else
                  Container(color: TerravaColors.surfaceContainer),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: TerravaColors.surfaceContainerLowest.withValues(
                      alpha: 0.92,
                    ),
                    shape: const CircleBorder(),
                    child: SaveListingButton(listingId: detail.id),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  detail.property.city,
                                  detail.property.state,
                                ].whereType<String>().join(', '),
                                style: const TextStyle(
                                  color: TerravaColors.secondaryFixed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                detail.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              formatFullPrice(
                                price: detail.price,
                                currency: detail.currency,
                                pricePeriod: detail.pricePeriod,
                                transactionType: detail.transactionType,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (specs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TerravaColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: specs),
          ),
      ],
    );
  }
}

class _MiniSpec extends StatelessWidget {
  const _MiniSpec({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 17, color: TerravaColors.onSurfaceVariant),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
