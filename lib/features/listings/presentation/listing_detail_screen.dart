import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/listings/data/listings_repository.dart';
import 'package:terrava/features/listings/presentation/listing_detail_view.dart';

@RoutePage()
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, @PathParam('id') required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(listingsRepositoryProvider).fetchListingDetail(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                snapshot.error?.toString() ?? 'Listing unavailable',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final listing = snapshot.data!;
        return Scaffold(
          backgroundColor: TerravaColors.background,
          body: SafeArea(
            bottom: false,
            child: ListingDetailView(listing: listing),
          ),
          bottomNavigationBar: ListingContactBar(
            listing: listing,
            onContact: () => openListingInquiry(context, ref, listing),
          ),
        );
      },
    );
  }
}
