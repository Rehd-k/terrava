import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';
import 'package:terrava/features/map/providers/location_provider.dart';
import 'package:terrava/features/messaging/data/messaging_repository.dart';
import 'package:terrava/features/messaging/providers/conversations_provider.dart';
import 'package:terrava/features/saved/presentation/save_listing_button.dart';

class ListingDetailView extends ConsumerStatefulWidget {
  const ListingDetailView({
    super.key,
    required this.listing,
    this.scrollController,
    this.showChrome = true,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final ListingDetail listing;
  final ScrollController? scrollController;
  final bool showChrome;
  final Widget? header;
  final EdgeInsets padding;

  @override
  ConsumerState<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<ListingDetailView> {
  int _slide = 0;

  ListingDetail get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(locationControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final images = listing.media
        .where((m) => m.mediaType == 'IMAGE')
        .toList(growable: false);
    final distance = formatDistanceFromUser(
      listingLat: listing.property.latitude,
      listingLng: listing.property.longitude,
      userLat: location.position?.latitude,
      userLng: location.position?.longitude,
    );

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (widget.header != null) widget.header!,
              if (widget.showChrome) ...[
                _DetailChrome(listing: listing),
                const SizedBox(height: 12),
              ],
              _PhotoCarousel(
                images: images,
                index: _slide,
                onChanged: (i) => setState(() => _slide = i),
              ),
              if (listing.reviewNote != null &&
                  listing.reviewNote!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TerravaColors.tertiaryFixed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reviewer note',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(listing.reviewNote!),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _TitleCard(listing: listing, distance: distance),
              const SizedBox(height: 12),
              _CostBreakdownCard(listing: listing),
              const SizedBox(height: 12),
              _SpecsGrid(listing: listing),
              const SizedBox(height: 12),
              _ListerCard(
                listing: listing,
                onMessage: () => openListingInquiry(context, ref, listing),
              ),
              if ((listing.description ?? listing.property.description) !=
                  null) ...[
                const SizedBox(height: 12),
                _NarrativeCard(listing: listing),
              ],
              if (listing.property.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                _AmenitiesCard(listing: listing),
              ],
              const SizedBox(height: 12),
              _LocationCard(listing: listing, distance: distance),
              const SizedBox(height: 88),
            ]),
          ),
        ),
      ],
    );
  }
}

class ListingContactBar extends StatelessWidget {
  const ListingContactBar({
    super.key,
    required this.listing,
    required this.onContact,
  });

  final ListingDetail listing;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest.withValues(alpha: 0.94),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatFullPrice(
                        price: listing.price,
                        currency: listing.currency,
                        pricePeriod: listing.pricePeriod,
                        transactionType: listing.transactionType,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '${listedByLabel(listing.listedBy)} · ${listing.lister.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TerravaColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onContact,
                style: FilledButton.styleFrom(
                  backgroundColor: TerravaColors.primary,
                  foregroundColor: TerravaColors.onPrimary,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.forum, size: 18),
                label: Text('Contact ${listing.lister.name.split(' ').first}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openListingInquiry(
  BuildContext context,
  WidgetRef ref,
  ListingDetail listing,
) async {
  var user = ref.read(authSessionProvider).asData?.value;
  if (user == null) {
    final signedIn = await context.router.push<bool>(const SignInRoute());
    if (signedIn != true || !context.mounted) {
      return;
    }
    user = ref.read(authSessionProvider).asData?.value;
  }
  if (user == null) {
    return;
  }
  if (user.id == listing.lister.id) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This is your listing')));
    }
    return;
  }

  try {
    final conversation = await ref
        .read(messagingRepositoryProvider)
        .startConversation(listingId: listing.id);
    ref.read(conversationsProvider.notifier).upsert(conversation);
    if (context.mounted) {
      await context.router.push(ConversationRoute(id: conversation.id));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not start conversation',
          ),
        ),
      );
    }
  }
}

class _DetailChrome extends StatelessWidget {
  const _DetailChrome({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundAction(
          icon: Icons.chevron_left,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Text(
                [
                  listing.property.city,
                  listing.property.state,
                ].whereType<String>().where((e) => e.isNotEmpty).join(', '),
                style: const TextStyle(
                  color: TerravaColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                listing.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        _RoundAction(
          icon: Icons.share_outlined,
          onTap: () async {
            final address = [
              listing.property.address,
              listing.property.city,
              listing.property.state,
            ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
            await Clipboard.setData(
              ClipboardData(text: '${listing.title}\n$address'),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing copied to clipboard')),
              );
            }
          },
        ),
        const SizedBox(width: 6),
        Material(
          color: TerravaColors.surfaceContainerLowest,
          shape: const CircleBorder(),
          elevation: 1,
          child: SaveListingButton(listingId: listing.id),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: TerravaColors.onSurface),
        ),
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({
    required this.images,
    required this.index,
    required this.onChanged,
  });

  final List<ListingMedia> images;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 210,
          color: TerravaColors.surfaceContainer,
          alignment: Alignment.center,
          child: const Icon(Icons.photo_outlined, size: 40),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 210,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: onChanged,
                  itemBuilder: (context, i) {
                    return CachedNetworkImage(
                      imageUrl: images[i].url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (_, __, ___) => Container(
                        color: TerravaColors.surfaceContainer,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: TerravaColors.surfaceContainerLowest.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${index + 1} / ${images.length} Photos',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: i == index
                        ? TerravaColors.primary.withValues(alpha: 0.12)
                        : TerravaColors.surfaceContainerHigh,
                    child: CachedNetworkImage(
                      imageUrl: images[i].thumbnailUrl ?? images[i].url,
                      width: 64,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.listing, required this.distance});

  final ListingDetail listing;
  final String distance;

  @override
  Widget build(BuildContext context) {
    final address = [
      listing.property.address,
      listing.property.city,
      listing.property.state,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    final isLand = listing.property.type == 'LAND';
    final badge = isLand
        ? 'Land Plot · ${transactionLabel(listing.transactionType)}'
        : '${transactionLabel(listing.transactionType)} · ${propertyTypeLabel(listing.property.type)}';

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: TerravaColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: const TextStyle(
                    color: TerravaColors.onSecondaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatListedAgo(listing.createdAt),
                style: const TextStyle(
                  color: TerravaColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            listing.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: TerravaColors.secondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address),
                      const SizedBox(height: 2),
                      Text(
                        distance,
                        style: const TextStyle(
                          color: TerravaColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CostBreakdownCard extends StatelessWidget {
  const _CostBreakdownCard({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    final principalLabel = listing.isRecurring
        ? 'Annual ${listing.transactionType == 'LEASE' ? 'lease' : 'rent'}'
        : 'Property cost';

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost breakdown',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            pricePeriodLabel(
              listing.pricePeriod,
              transactionType: listing.transactionType,
            ),
            style: const TextStyle(
              color: TerravaColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _FeeRow(
            label: principalLabel,
            value: formatFullPrice(
              price: listing.price,
              currency: listing.currency,
              pricePeriod: listing.pricePeriod,
              transactionType: listing.transactionType,
            ),
            emphasis: true,
          ),
          _FeeRow(
            label: 'Agency fee',
            value: listing.agencyFee == null || listing.agencyFee == 0
                ? 'None'
                : formatFullPrice(
                    price: listing.agencyFee!,
                    currency: listing.currency,
                  ),
          ),
          _FeeRow(
            label: 'Legal fee',
            value: listing.legalFee == null || listing.legalFee == 0
                ? 'None'
                : formatFullPrice(
                    price: listing.legalFee!,
                    currency: listing.currency,
                  ),
          ),
          const Divider(height: 20),
          _FeeRow(
            label: 'Total due',
            value: formatFullPrice(
              price: listing.totalDue,
              currency: listing.currency,
              pricePeriod: listing.pricePeriod,
              transactionType: listing.transactionType,
            ),
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasis
                    ? TerravaColors.onSurface
                    : TerravaColors.onSurfaceVariant,
                fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: emphasis ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    final tiles = <_SpecData>[];
    final property = listing.property;
    final isLand = property.type == 'LAND';
    final isRent =
        listing.transactionType == 'RENT' || listing.transactionType == 'LEASE';

    if (isLand) {
      if (property.landSize != null) {
        tiles.add(
          _SpecData(
            Icons.landscape_outlined,
            formatLandSize(property.landSize!),
            'Plot size',
          ),
        );
      }
      tiles.add(
        _SpecData(
          Icons.description_outlined,
          listedByLabel(listing.listedBy),
          'Seller',
        ),
      );
      final docs = property.amenities
          .where(
            (a) =>
                a.toLowerCase().contains('c of o') ||
                a.toLowerCase().contains('deed') ||
                a.toLowerCase().contains('survey'),
          )
          .toList();
      if (docs.isNotEmpty) {
        tiles.add(_SpecData(Icons.policy_outlined, docs.first, 'Title / docs'));
      }
      tiles.add(const _SpecData(Icons.crop_free, 'Vacant plot', 'Use'));
    } else {
      if (property.bedrooms != null) {
        tiles.add(
          _SpecData(Icons.bed_outlined, '${property.bedrooms} Beds', 'Rooms'),
        );
      }
      if (property.bathrooms != null) {
        tiles.add(
          _SpecData(
            Icons.bathtub_outlined,
            '${property.bathrooms} Baths',
            'Bathrooms',
          ),
        );
      }
      if (property.propertySize != null) {
        tiles.add(
          _SpecData(
            Icons.square_foot,
            formatInteriorSize(property.propertySize!),
            'Interior',
          ),
        );
      }
      if (property.landSize != null) {
        tiles.add(
          _SpecData(
            Icons.landscape_outlined,
            formatLandSize(property.landSize!),
            'Lot',
          ),
        );
      }
      if (isRent) {
        tiles.add(
          const _SpecData(Icons.calendar_month, 'Annual term', 'Tenancy'),
        );
      }
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: [
        for (final tile in tiles)
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tile.icon, size: 18, color: TerravaColors.onSurface),
                const Spacer(),
                Text(
                  tile.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  tile.caption,
                  style: const TextStyle(
                    color: TerravaColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SpecData {
  const _SpecData(this.icon, this.value, this.caption);

  final IconData icon;
  final String value;
  final String caption;
}

class _ListerCard extends StatelessWidget {
  const _ListerCard({required this.listing, required this.onMessage});

  final ListingDetail listing;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final lister = listing.lister;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: lister.profileImageUrl == null
                    ? null
                    : CachedNetworkImageProvider(lister.profileImageUrl!),
                child: lister.profileImageUrl == null
                    ? Text(
                        lister.name.isNotEmpty
                            ? lister.name[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lister.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (lister.verificationStatus == 'VERIFIED') ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: TerravaColors.secondary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      listedByLabel(listing.listedBy),
                      style: const TextStyle(
                        color: TerravaColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onMessage,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this property',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            listing.description ?? listing.property.description ?? '',
            style: const TextStyle(
              color: TerravaColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesCard extends StatelessWidget {
  const _AmenitiesCard({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amenity in listing.property.amenities)
                Chip(
                  label: Text(amenity),
                  backgroundColor: TerravaColors.surfaceContainerLow,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.listing, required this.distance});

  final ListingDetail listing;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            [
              listing.property.address,
              listing.property.city,
              listing.property.state,
              listing.property.country,
            ].whereType<String>().where((e) => e.isNotEmpty).join(', '),
            style: const TextStyle(color: TerravaColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.near_me,
                size: 16,
                color: TerravaColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  distance,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
