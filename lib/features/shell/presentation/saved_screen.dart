import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';
import 'package:terrava/features/saved/data/saved_listing.dart';
import 'package:terrava/features/saved/providers/saved_listings_provider.dart';

enum _ViewMode { list, map }

enum _SortMode { recent, price }

@RoutePage()
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  _ViewMode _viewMode = _ViewMode.list;
  _SortMode _sort = _SortMode.recent;
  String? _filterType;
  String? _focusedId;
  final _geoKey = GlobalKey();

  void _goMap() => AutoTabsRouter.of(context).setActiveIndex(0);

  void _goProfile() => AutoTabsRouter.of(context).setActiveIndex(3);

  List<SavedListing> _visible(List<SavedListing> items) {
    var next = [...items];
    if (_filterType != null) {
      next = next.where((e) => e.transactionType == _filterType).toList();
    }
    next.sort((a, b) {
      if (_sort == _SortMode.price) {
        return b.price.compareTo(a.price);
      }
      return b.savedAt.compareTo(a.savedAt);
    });
    return next;
  }

  Future<void> _cycleSort() async {
    setState(() {
      _sort = _sort == _SortMode.recent ? _SortMode.price : _SortMode.recent;
    });
  }

  Future<void> _cycleFilter() async {
    const order = <String?>[null, 'SALE', 'RENT', 'LEASE'];
    final index = order.indexOf(_filterType);
    setState(() => _filterType = order[(index + 1) % order.length]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);
    final saved = ref.watch(savedListingsProvider);
    final user = auth.asData?.value;
    final bottomInset = 96 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TerravaColors.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'TERRA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: TerravaColors.primary,
              ),
            ),
            Text(
              ' · SAVED',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: TerravaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _goProfile,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: TerravaColors.surfaceContainerHighest,
                backgroundImage: user?.profileImageUrl == null
                    ? null
                    : CachedNetworkImageProvider(user!.profileImageUrl!),
                child: user?.profileImageUrl == null
                    ? Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StatusBody(
          title: 'Could not load your session',
          body: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(authSessionProvider),
          bottomInset: bottomInset,
        ),
        data: (sessionUser) {
          if (sessionUser == null) {
            return _StatusBody(
              title: 'Sign in to save listings',
              body:
                  'Bookmark beacons from the map or a listing dossier. They live here with your account.',
              actionLabel: 'Sign in',
              onAction: () async {
                final signedIn = await context.router.push<bool>(
                  const SignInRoute(),
                );
                if (signedIn == true) {
                  await ref.read(savedListingsProvider.notifier).refresh();
                }
              },
              bottomInset: bottomInset,
            );
          }

          return saved.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _StatusBody(
              title: 'Saved listings unavailable',
              body: error.toString(),
              actionLabel: 'Retry',
              onAction: () =>
                  ref.read(savedListingsProvider.notifier).refresh(),
              bottomInset: bottomInset,
            ),
            data: (items) {
              final visible = _visible(items);
              if (items.isEmpty) {
                return _EmptyState(onExplore: _goMap, bottomInset: bottomInset);
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(savedListingsProvider.notifier).refresh(),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
                  children: [
                    Text(
                      '${items.length} saved beacon${items.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ModeChip(
                          label: 'List',
                          selected: _viewMode == _ViewMode.list,
                          onTap: () =>
                              setState(() => _viewMode = _ViewMode.list),
                        ),
                        const SizedBox(width: 8),
                        _ModeChip(
                          label: 'Map radar',
                          selected: _viewMode == _ViewMode.map,
                          onTap: () {
                            setState(() => _viewMode = _ViewMode.map);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_geoKey.currentContext != null) {
                                Scrollable.ensureVisible(
                                  _geoKey.currentContext!,
                                  duration: const Duration(milliseconds: 350),
                                  alignment: 0.1,
                                );
                              }
                            });
                          },
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _cycleSort,
                          child: Text(
                            _sort == _SortMode.recent ? 'Recent' : 'Price',
                          ),
                        ),
                        TextButton(
                          onPressed: _cycleFilter,
                          child: Text(_filterType ?? 'All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No saved listings match this filter.',
                            style: TextStyle(
                              color: TerravaColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      KeyedSubtree(
                        key: _geoKey,
                        child: _RadarCard(
                          items: visible,
                          focusedId: _focusedId,
                          highlighted: _viewMode == _ViewMode.map,
                          onExpand: _goMap,
                          onSelect: (id) {
                            setState(() => _focusedId = id);
                            context.router.root.push(
                              ListingDetailRoute(id: id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final listing in visible) ...[
                        _SavedCard(
                          listing: listing,
                          onOpen: () => context.router.root.push(
                            ListingDetailRoute(id: listing.id),
                          ),
                          onUnsave: () => ref
                              .read(savedListingsProvider.notifier)
                              .unsave(listing.id),
                          onLocate: () {
                            setState(() {
                              _focusedId = listing.id;
                              _viewMode = _ViewMode.map;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_geoKey.currentContext != null) {
                                Scrollable.ensureVisible(
                                  _geoKey.currentContext!,
                                  duration: const Duration(milliseconds: 350),
                                  alignment: 0.05,
                                );
                              }
                            });
                          },
                          onShare: () async {
                            final text = listing.city == null
                                ? listing.title
                                : '${listing.title} · ${listing.city}';
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied listing')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? TerravaColors.primary
          : TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: selected
                  ? TerravaColors.onPrimary
                  : TerravaColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.items,
    required this.focusedId,
    required this.highlighted,
    required this.onExpand,
    required this.onSelect,
  });

  final List<SavedListing> items;
  final String? focusedId;
  final bool highlighted;
  final VoidCallback onExpand;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: TerravaColors.mapCanvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? TerravaColors.secondary
              : TerravaColors.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          for (final item in items)
            Positioned(
              left:
                  _left(item, items) * (MediaQuery.sizeOf(context).width - 64),
              top: _top(item, items) * 140,
              child: GestureDetector(
                onTap: () => onSelect(item.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.id == focusedId
                        ? TerravaColors.primary
                        : TerravaColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formatListingPrice(
                      price: item.price,
                      currency: item.currency,
                      transactionType: item.transactionType,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.id == focusedId
                          ? TerravaColors.onPrimary
                          : TerravaColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: TextButton(
              onPressed: onExpand,
              child: const Text('Expand map'),
            ),
          ),
        ],
      ),
    );
  }

  static double _norm(double value, double min, double max) {
    if ((max - min).abs() < 0.0001) return 0.5;
    return ((value - min) / (max - min)).clamp(0.08, 0.85);
  }

  static double _left(SavedListing item, List<SavedListing> items) {
    final lngs = items.map((e) => e.longitude);
    return _norm(
      item.longitude,
      lngs.reduce((a, b) => a < b ? a : b),
      lngs.reduce((a, b) => a > b ? a : b),
    );
  }

  static double _top(SavedListing item, List<SavedListing> items) {
    final lats = items.map((e) => e.latitude);
    final min = lats.reduce((a, b) => a < b ? a : b);
    final max = lats.reduce((a, b) => a > b ? a : b);
    return 1 - _norm(item.latitude, min, max);
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.listing,
    required this.onOpen,
    required this.onUnsave,
    required this.onLocate,
    required this.onShare,
  });

  final SavedListing listing;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;
  final VoidCallback onLocate;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: listing.thumbnailUrl == null
                    ? const ColoredBox(color: TerravaColors.surfaceContainer)
                    : CachedNetworkImage(
                        imageUrl: listing.thumbnailUrl!,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filled(
                  onPressed: onUnsave,
                  style: IconButton.styleFrom(
                    backgroundColor: TerravaColors.surfaceContainerLowest,
                    foregroundColor: TerravaColors.error,
                  ),
                  icon: const Icon(Icons.favorite),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transactionLabel(listing.transactionType)} · ${propertyTypeLabel(listing.propertyType)}',
                  style: const TextStyle(
                    color: TerravaColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (listing.city != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    listing.city!,
                    style: const TextStyle(
                      color: TerravaColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  formatFullPrice(
                    price: listing.price,
                    currency: listing.currency,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: TerravaColors.primary,
                        foregroundColor: TerravaColors.onPrimary,
                      ),
                      child: const Text('View dossier'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onLocate,
                      icon: const Icon(Icons.near_me_outlined),
                    ),
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExplore, required this.bottomInset});

  final VoidCallback onExplore;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 36,
              color: TerravaColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved beacons yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a listing and tap the heart to keep it in your collection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TerravaColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: TerravaColors.primary,
                foregroundColor: TerravaColors.onPrimary,
              ),
              child: const Text('Explore map discovery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.title,
    required this.body,
    required this.bottomInset,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final double bottomInset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TerravaColors.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
