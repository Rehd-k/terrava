import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/features/admin/data/admin_models.dart';
import 'package:terrava/features/admin/data/admin_repository.dart';
import 'package:terrava/features/listings/data/listing_models.dart';

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.watch(adminRepositoryProvider).fetchStats();
});

final adminUsersProvider = FutureProvider.autoDispose
    .family<PaginatedAdminUsers, AdminUserQuery>((ref, query) {
      return ref.watch(adminRepositoryProvider).fetchUsers(query: query);
    });

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUser, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).fetchUser(id);
    });

final adminListingsProvider = FutureProvider.autoDispose
    .family<PaginatedAdminListings, AdminListingQuery>((ref, query) {
      return ref.watch(adminRepositoryProvider).fetchListings(query: query);
    });

final adminListingDetailProvider = FutureProvider.autoDispose
    .family<ListingDetail, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).fetchListing(id);
    });
