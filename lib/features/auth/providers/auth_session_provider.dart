import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/features/auth/data/auth_models.dart';
import 'package:terrava/features/auth/data/auth_repository.dart';

class AuthSessionNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    return ref.read(authRepositoryProvider).me();
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    state = AsyncData(auth.user);
    return auth.user;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .register(name: name, email: email, password: password);
    state = AsyncData(auth.user);
    return auth.user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<AuthUser> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .updateMe(name: name, phone: phone, profileImageUrl: profileImageUrl);
    state = AsyncData(user);
    return user;
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthUser?>(
      AuthSessionNotifier.new,
    );
