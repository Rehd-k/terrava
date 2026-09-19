import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/admin/data/admin_models.dart';
import 'package:terrava/features/admin/providers/admin_providers.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';

enum _ListingFilter { pending, approved, changes, rejected, suspended, all }

AdminListingQuery _queryFor(_ListingFilter filter) {
  return switch (filter) {
    _ListingFilter.pending => const AdminListingQuery(status: 'PENDING_REVIEW'),
    _ListingFilter.approved => const AdminListingQuery(status: 'APPROVED'),
    _ListingFilter.changes => const AdminListingQuery(
      status: 'CHANGES_REQUESTED',
    ),
    _ListingFilter.rejected => const AdminListingQuery(status: 'REJECTED'),
    _ListingFilter.suspended => const AdminListingQuery(status: 'SUSPENDED'),
    _ListingFilter.all => const AdminListingQuery(all: true),
  };
}

_ListingFilter _filterFromStatus(String? status) {
  return switch (status) {
    'APPROVED' => _ListingFilter.approved,
    'CHANGES_REQUESTED' => _ListingFilter.changes,
    'REJECTED' => _ListingFilter.rejected,
    'SUSPENDED' => _ListingFilter.suspended,
    'ALL' => _ListingFilter.all,
    _ => _ListingFilter.pending,
  };
}

@RoutePage()
class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key, @QueryParam('status') this.status});

  final String? status;

  @override
  ConsumerState<AdminListingsScreen> createState() =>
      _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen> {
  late _ListingFilter _filter = _filterFromStatus(widget.status);

  @override
  Widget build(BuildContext context) {
    final query = _queryFor(_filter);
    final listings = ref.watch(adminListingsProvider(query));

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      appBar: AppBar(
        backgroundColor: TerravaColors.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        titleSpacing: 0,
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
              ' / Listings',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(adminListingsProvider(query)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (page) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                'Listing review',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${page.total} in this filter',
                style: const TextStyle(color: TerravaColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in [
                      (_ListingFilter.pending, 'Pending'),
                      (_ListingFilter.approved, 'Approved'),
                      (_ListingFilter.changes, 'Changes'),
                      (_ListingFilter.rejected, 'Rejected'),
                      (_ListingFilter.suspended, 'Suspended'),
                      (_ListingFilter.all, 'All'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(entry.$2),
                          selected: _filter == entry.$1,
                          onSelected: (_) => setState(() => _filter = entry.$1),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (page.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'No listings in this status.',
                      style: TextStyle(color: TerravaColors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                for (final listing in page.items) ...[
                  _AdminListingCard(listing: listing),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _AdminListingCard extends StatelessWidget {
  const _AdminListingCard({required this.listing});

  final AdminListingSummary listing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.router.push(AdminListingReviewRoute(id: listing.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: listing.thumbnailUrl == null
                  ? const ColoredBox(color: TerravaColors.surfaceContainer)
                  : CachedNetworkImage(
                      imageUrl: listing.thumbnailUrl!,
                      fit: BoxFit.cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listingStatusLabel(listing.status),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: TerravaColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (listing.locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      listing.locationLabel,
                      style: const TextStyle(
                        color: TerravaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    listing.listerName,
                    style: const TextStyle(
                      color: TerravaColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatFullPrice(
                      price: listing.price,
                      currency: listing.currency,
                      transactionType: listing.transactionType,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
