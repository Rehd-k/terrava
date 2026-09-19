import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/data/listings_repository.dart';

final myListingsProvider = FutureProvider<List<OwnerListing>>((ref) async {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null) {
    return const [];
  }
  return ref.read(listingsRepositoryProvider).fetchMine();
});
