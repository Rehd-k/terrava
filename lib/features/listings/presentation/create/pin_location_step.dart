import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/listings/providers/create_listing_controller.dart';
import 'package:terrava/features/map/providers/location_provider.dart';
import 'package:terrava/features/map/providers/map_listings_provider.dart';

class PinLocationStep extends ConsumerStatefulWidget {
  const PinLocationStep({super.key});

  @override
  ConsumerState<PinLocationStep> createState() => _PinLocationStepState();
}

class _PinLocationStepState extends ConsumerState<PinLocationStep> {
  MapboxMap? _map;
  CameraViewportState? _viewport;
  Timer? _geocodeDebounce;
  var _moving = false;
  var _satellite = false;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  static const _fallback = MapLatLng(34.0522, -118.2437);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  MapLatLng get _initial {
    final draft = ref.read(createListingProvider);
    if (draft.hasPin) return MapLatLng(draft.latitude!, draft.longitude!);
    final position = ref.read(locationControllerProvider).position;
    if (position != null) {
      return MapLatLng(position.latitude, position.longitude);
    }
    return _fallback;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(createListingProvider);
    final location = ref.watch(locationControllerProvider);

    ref.listen(createListingProvider.select((s) => s.listingId), (_, id) async {
      final loaded = ref.read(createListingProvider);
      if (id == null || !loaded.hasPin || _map == null) return;
      await _map!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(loaded.longitude!, loaded.latitude!),
          ),
          zoom: 16,
        ),
      );
      if (loaded.address != null) _addressController.text = loaded.address!;
      if (loaded.city != null) _cityController.text = loaded.city!;
      if (loaded.state != null) _stateController.text = loaded.state!;
    });
    ref.listen(createListingProvider.select((s) => s.address), (_, next) {
      if (ref.read(createListingProvider).editingAddress) return;
      if (next != null && _addressController.text != next) {
        _addressController.text = next;
      }
    });
    ref.listen(createListingProvider.select((s) => s.city), (_, next) {
      if (next != null && _cityController.text != next) {
        _cityController.text = next;
      }
    });
    ref.listen(createListingProvider.select((s) => s.state), (_, next) {
      if (next != null && _stateController.text != next) {
        _stateController.text = next;
      }
    });

    final coords = draft.hasPin
        ? '${draft.latitude!.abs().toStringAsFixed(4)}° ${draft.latitude! >= 0 ? 'N' : 'S'}, ${draft.longitude!.abs().toStringAsFixed(4)}° ${draft.longitude! >= 0 ? 'E' : 'W'}'
        : 'Waiting for map';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TerravaColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'STEP 2 OF 3 · LOCATION & PIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: TerravaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Where is your property located?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Terrava is map-first. Accurate coordinates ensure nearby buyers discover your listing directly.',
          style: TextStyle(color: TerravaColors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const _PulseDot(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS ${location.permission == LocationPermissionStatus.granted ? 'Coordinates Detected' : 'seeking lock'} ($coords)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                location.permission == LocationPermissionStatus.granted
                    ? Icons.verified
                    : Icons.gps_not_fixed,
                size: 18,
                color: TerravaColors.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 288,
            child: Stack(
              children: [
                _buildMap(),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TerravaColors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: TerravaColors.secondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pan the map to drop the pin on the entrance',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 140),
                    offset: _moving ? const Offset(0, -0.08) : Offset.zero,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 140),
                      scale: _moving ? 1.08 : 1,
                      child: const _PrecisionPin(),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _MiniHud(
                        icon: Icons.my_location,
                        color: TerravaColors.secondary,
                        onTap: _recenter,
                      ),
                      const SizedBox(height: 8),
                      _MiniHud(
                        icon: Icons.layers,
                        onTap: () {
                          setState(() => _satellite = !_satellite);
                          _map?.loadStyleURI(
                            _satellite
                                ? MapboxStyles.STANDARD_SATELLITE
                                : MapboxStyles.STANDARD,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: TerravaColors.surface.withValues(alpha: 0.85),
                    child: Text(
                      (draft.city ?? 'MAP PIN').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: TerravaColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: TerravaColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DETECTED ADDRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: TerravaColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      final editing = !draft.editingAddress;
                      notifierSetEditing(editing);
                      if (!editing) {
                        ref
                            .read(createListingProvider.notifier)
                            .setAddressFields(
                              address: _addressController.text.trim(),
                              city: _cityController.text.trim(),
                              state: _stateController.text.trim(),
                              country: draft.country,
                            );
                      }
                    },
                    icon: Icon(
                      draft.editingAddress ? Icons.check : Icons.edit,
                      size: 16,
                    ),
                    label: Text(draft.editingAddress ? 'Done' : 'Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: draft.editingAddress
                          ? TerravaColors.onPrimary
                          : TerravaColors.onSurface,
                      backgroundColor: draft.editingAddress
                          ? TerravaColors.primary
                          : TerravaColors.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (draft.editingAddress) ...[
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street address',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  draft.address?.isNotEmpty == true
                      ? draft.address!
                      : 'Pan the map to detect an address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (draft.city != null || draft.state != null)
                  Text(
                    [
                      draft.city,
                      draft.state,
                    ].whereType<String>().where((e) => e.isNotEmpty).join(', '),
                    style: const TextStyle(
                      color: TerravaColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TerravaColors.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: TerravaColors.secondaryContainer,
                child: Icon(
                  Icons.shield,
                  size: 18,
                  color: TerravaColors.onSecondaryContainer,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public Map Display Protection',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your exact street address is kept confidential until you approve a verified tour request. Only the approximate neighborhood beacon is visible on public discovery.',
                      style: TextStyle(
                        fontSize: 13,
                        color: TerravaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void notifierSetEditing(bool value) {
    ref.read(createListingProvider.notifier).setEditingAddress(value);
  }

  Widget _buildMap() {
    if (kIsWeb) {
      return const ColoredBox(
        color: TerravaColors.mapCanvas,
        child: Center(child: Text('Maps are available on iOS and Android.')),
      );
    }

    _viewport ??= CameraViewportState(
      center: Point(
        coordinates: Position(_initial.longitude, _initial.latitude),
      ),
      zoom: 16,
      bearing: 0,
      pitch: 0,
    );

    return MapWidget(
      key: const ValueKey('create-listing-pin-map'),
      styleUri: _satellite
          ? MapboxStyles.STANDARD_SATELLITE
          : MapboxStyles.STANDARD,
      viewport: _viewport,
      onMapCreated: (map) async {
        _map = map;
        await map.compass.updateSettings(CompassSettings(enabled: false));
        await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
        await _syncFromCamera();
      },
      onCameraChangeListener: (event) {
        if (!_moving && mounted) setState(() => _moving = true);
        final coords = event.cameraState.center.coordinates;
        ref
            .read(createListingProvider.notifier)
            .setPin(coords.lat.toDouble(), coords.lng.toDouble());
      },
      onMapIdleListener: (_) {
        if (_moving && mounted) setState(() => _moving = false);
        _geocodeDebounce?.cancel();
        _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
          _syncFromCamera();
        });
      },
    );
  }

  Future<void> _syncFromCamera() async {
    final map = _map;
    if (map == null) return;
    final camera = await map.getCameraState();
    final lat = camera.center.coordinates.lat.toDouble();
    final lng = camera.center.coordinates.lng.toDouble();
    await ref.read(createListingProvider.notifier).reverseGeocode(lat, lng);
  }

  Future<void> _recenter() async {
    await ref.read(locationControllerProvider.notifier).initialize();
    final position = ref.read(locationControllerProvider).position;
    if (position == null || _map == null) return;
    await _map!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 16,
      ),
      MapAnimationOptions(duration: 700),
    );
  }
}

class _PrecisionPin extends StatelessWidget {
  const _PrecisionPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: TerravaColors.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TerravaColors.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'New Listing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                '  ·  Drag to adjust',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const CircleAvatar(
          radius: 20,
          backgroundColor: TerravaColors.primary,
          child: Icon(Icons.villa, color: TerravaColors.secondaryFixed),
        ),
        Container(width: 2, height: 12, color: TerravaColors.primary),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: TerravaColors.secondary,
            shape: BoxShape.circle,
            border: Border.all(
              color: TerravaColors.secondary.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniHud extends StatelessWidget {
  const _MiniHud({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: color ?? TerravaColors.onSurface),
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TerravaColors.secondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
