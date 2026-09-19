import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/saved/data/saved_listing.dart';
import 'package:terrava/features/saved/data/saved_properties_repository.dart';

class SavedListingsNotifier extends AsyncNotifier<List<SavedListing>> {
  @override
  Future<List<SavedListing>> build() async {
    final user = ref.watch(authSessionProvider).asData?.value;
    if (user == null) {
      return const [];
    }
    return ref.read(savedPropertiesRepositoryProvider).list();
  }

  Future<void> refresh() async {
    final user = ref.read(authSessionProvider).asData?.value;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(savedPropertiesRepositoryProvider).list(),
    );
  }

  Future<void> save(String listingId) async {
    final item = await ref
        .read(savedPropertiesRepositoryProvider)
        .save(listingId);
    final current = [...(state.asData?.value ?? const <SavedListing>[])];
    current.removeWhere((e) => e.id == item.id);
    state = AsyncData([item, ...current]);
  }

  Future<void> unsave(String listingId) async {
    final previous = [...(state.asData?.value ?? const <SavedListing>[])];
    state = AsyncData([
      for (final item in previous)
        if (item.id != listingId) item,
    ]);
    try {
      await ref.read(savedPropertiesRepositoryProvider).unsave(listingId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  bool contains(String listingId) {
    return state.asData?.value.any((e) => e.id == listingId) ?? false;
  }
}

final savedListingsProvider =
    AsyncNotifierProvider<SavedListingsNotifier, List<SavedListing>>(
      SavedListingsNotifier.new,
    );

final savedListingIdsProvider = Provider<Set<String>>((ref) {
  final items = ref.watch(savedListingsProvider).asData?.value;
  return items == null ? const {} : {for (final item in items) item.id};
});
