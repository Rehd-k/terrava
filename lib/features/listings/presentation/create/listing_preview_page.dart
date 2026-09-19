import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/listings/presentation/listing_beacon.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';
import 'package:terrava/features/listings/providers/create_listing_controller.dart';

class ListingPreviewPage extends ConsumerStatefulWidget {
  const ListingPreviewPage({super.key});

  @override
  ConsumerState<ListingPreviewPage> createState() => _ListingPreviewPageState();
}

class _ListingPreviewPageState extends ConsumerState<ListingPreviewPage> {
  MapboxMap? _map;
  PointAnnotationManager? _manager;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(createListingProvider);
    final lat = draft.latitude ?? 5.0377;
    final lng = draft.longitude ?? 7.9128;
    final label = formatListingPrice(
      price: draft.price,
      currency: draft.currency,
      transactionType: draft.transactionType,
      pricePeriod: draft.pricePeriod,
      propertyType: draft.propertyType,
      landSize: draft.landSize,
    );
    final cover = draft.photos
        .map((p) => p.url)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .fold<String?>(null, (prev, url) => prev ?? url);

    return Scaffold(
      backgroundColor: TerravaColors.mapCanvas,
      body: Stack(
        children: [
          if (kIsWeb)
            const ColoredBox(
              color: TerravaColors.mapCanvas,
              child: Center(
                child: Text('Maps are available on iOS and Android.'),
              ),
            )
          else
            MapWidget(
              key: const ValueKey('listing-preview-map'),
              styleUri: MapboxStyles.STANDARD,
              viewport: CameraViewportState(
                center: Point(coordinates: Position(lng, lat)),
                zoom: 15,
              ),
              onMapCreated: (map) async {
                _map = map;
                await map.compass.updateSettings(
                  CompassSettings(enabled: false),
                );
                await map.scaleBar.updateSettings(
                  ScaleBarSettings(enabled: false),
                );
              },
              onStyleLoadedListener: (_) async {
                await _placeBeacon(lat, lng, label, draft);
              },
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Material(
                    color: TerravaColors.surface.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TerravaColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Local preview · not on the public map',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Material(
                color: TerravaColors.surfaceContainerLowest.withValues(
                  alpha: 0.96,
                ),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cover != null)
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${transactionLabel(draft.transactionType)} · ${propertyTypeLabel(draft.propertyType)}',
                            style: const TextStyle(
                              color: TerravaColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            draft.title ??
                                '${propertyTypeLabel(draft.propertyType)} for ${transactionLabel(draft.transactionType).toLowerCase()}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (draft.address != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                draft.address,
                                draft.city,
                              ].whereType<String>().join(', '),
                              style: const TextStyle(
                                color: TerravaColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            formatFullPrice(
                              price: draft.price,
                              currency: draft.currency,
                              pricePeriod: draft.pricePeriod,
                              transactionType: draft.transactionType,
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeBeacon(
    double lat,
    double lng,
    String label,
    CreateListingState draft,
  ) async {
    final map = _map;
    if (map == null) return;
    if (_manager != null) {
      await map.annotations.removeAnnotationManager(_manager!);
    }
    _manager = await map.annotations.createPointAnnotationManager();
    await _manager!.setIconAllowOverlap(true);
    final icon = await createListingBeaconBitmap(
      label: label,
      propertyType: draft.propertyType,
      transactionType: draft.transactionType,
      selected: true,
    );
    await _manager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        image: icon,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );
  }
}
