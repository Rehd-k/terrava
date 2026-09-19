import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/presentation/create/create_listing_entry.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';
import 'package:terrava/features/listings/providers/my_listings_provider.dart';

enum _ListingFilter {
  all,
  draft,
  approved,
  pending,
  changes,
  rejected,
  suspended,
}

String? _statusFor(_ListingFilter filter) {
  return switch (filter) {
    _ListingFilter.all => null,
    _ListingFilter.draft => 'DRAFT',
    _ListingFilter.approved => 'APPROVED',
    _ListingFilter.pending => 'PENDING_REVIEW',
    _ListingFilter.changes => 'CHANGES_REQUESTED',
    _ListingFilter.rejected => 'REJECTED',
    _ListingFilter.suspended => 'SUSPENDED',
  };
}

@RoutePage()
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  _ListingFilter _filter = _ListingFilter.all;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);
    final listings = ref.watch(myListingsProvider);
    final user = auth.asData?.value;

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openCreateListing(context, ref),
              backgroundColor: TerravaColors.primary,
              foregroundColor: TerravaColors.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('List a property'),
            ),
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
              ' / My Listings',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
        ],
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (sessionUser) {
          if (sessionUser == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.router.push(const SignInRoute()),
                child: const Text('Sign in'),
              ),
            );
          }

          return listings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString()),
                  TextButton(
                    onPressed: () => ref.invalidate(myListingsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (items) {
              final visible = _filter == _ListingFilter.all
                  ? items
                  : items
                        .where((e) => e.status == _statusFor(_filter))
                        .toList();
              int count(String status) =>
                  items.where((e) => e.status == status).length;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Text(
                    'My Listings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review status for every beacon you have submitted.',
                    style: TextStyle(color: TerravaColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in [
                          (_ListingFilter.all, 'All', items.length),
                          (_ListingFilter.draft, 'Draft', count('DRAFT')),
                          (
                            _ListingFilter.approved,
                            'Approved',
                            count('APPROVED'),
                          ),
                          (
                            _ListingFilter.pending,
                            'Pending',
                            count('PENDING_REVIEW'),
                          ),
                          (
                            _ListingFilter.changes,
                            'Changes',
                            count('CHANGES_REQUESTED'),
                          ),
                          (
                            _ListingFilter.rejected,
                            'Rejected',
                            count('REJECTED'),
                          ),
                          (
                            _ListingFilter.suspended,
                            'Suspended',
                            count('SUSPENDED'),
                          ),
                        ]) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('${entry.$2} ${entry.$3}'),
                              selected: _filter == entry.$1,
                              onSelected: (_) =>
                                  setState(() => _filter = entry.$1),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No listings in this status.',
                          style: TextStyle(
                            color: TerravaColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final listing in visible) ...[
                      _OwnerCard(listing: listing),
                      const SizedBox(height: 16),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerCard extends ConsumerWidget {
  const _OwnerCard({required this.listing});

  final OwnerListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = listing.status == 'APPROVED';
    final editable =
        listing.status == 'DRAFT' || listing.status == 'CHANGES_REQUESTED';
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: approved
            ? () => context.router.push(ListingDetailRoute(id: listing.id))
            : editable
            ? () => openCreateListing(context, ref, listingId: listing.id)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
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
                    listing.status.replaceAll('_', ' '),
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
                  const SizedBox(height: 8),
                  Text(
                    formatFullPrice(
                      price: listing.price,
                      currency: listing.currency,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (listing.reviewNote != null &&
                      listing.reviewNote!.isNotEmpty &&
                      (listing.status == 'REJECTED' ||
                          listing.status == 'CHANGES_REQUESTED')) ...[
                    const SizedBox(height: 10),
                    Text(
                      listing.reviewNote!,
                      style: const TextStyle(
                        color: TerravaColors.onTertiaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
