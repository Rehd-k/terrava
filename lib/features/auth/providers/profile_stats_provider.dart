import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/features/auth/data/auth_models.dart';
import 'package:terrava/features/auth/data/auth_repository.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/saved/providers/saved_listings_provider.dart';

final profileStatsProvider = FutureProvider<UserStats?>((ref) async {
  final user = ref.watch(authSessionProvider).asData?.value;
  ref.watch(savedListingsProvider);
  if (user == null) {
    return null;
  }
  return ref.read(authRepositoryProvider).stats();
});
