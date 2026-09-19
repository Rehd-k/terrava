import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/admin/data/admin_models.dart';
import 'package:terrava/features/admin/data/admin_repository.dart';
import 'package:terrava/features/admin/providers/admin_providers.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';

@RoutePage()
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, @PathParam('id') required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminUserDetailProvider(id));
    final session = ref.watch(authSessionProvider).asData?.value;

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      appBar: AppBar(
        backgroundColor: TerravaColors.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('User'),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(adminUserDetailProvider(id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (user) {
          final isSelf = session?.id == user.id;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: TerravaColors.surfaceContainer,
                    backgroundImage: user.profileImageUrl == null
                        ? null
                        : CachedNetworkImageProvider(user.profileImageUrl!),
                    child: user.profileImageUrl == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: TerravaColors.onSurfaceVariant,
                          ),
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          Text(user.phone!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: verificationLabel(user.verificationStatus)),
                  _InfoChip(label: user.accountStatus),
                  _InfoChip(label: user.role),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _CountBox(label: 'Listings', value: user.listings ?? 0),
                  const SizedBox(width: 8),
                  _CountBox(label: 'Live', value: user.liveListings ?? 0),
                  const SizedBox(width: 8),
                  _CountBox(label: 'Pending', value: user.pendingListings ?? 0),
                ],
              ),
              const SizedBox(height: 24),
              if (!user.isVerified)
                FilledButton(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => ref.read(adminRepositoryProvider).verifyUser(id),
                    'User verified',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: TerravaColors.primary,
                    foregroundColor: TerravaColors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Verify user'),
                ),
              if (user.isPending) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => ref
                        .read(adminRepositoryProvider)
                        .rejectVerification(id),
                    'Verification rejected',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Reject verification'),
                ),
              ],
              if (user.isVerified && !user.isPending) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => ref
                        .read(adminRepositoryProvider)
                        .rejectVerification(id),
                    'Verification removed',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Remove verification'),
                ),
              ],
              const SizedBox(height: 8),
              if (user.isSuspended)
                OutlinedButton(
                  onPressed: () => _run(
                    context,
                    ref,
                    () => ref.read(adminRepositoryProvider).activateUser(id),
                    'Account reactivated',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Reactivate account'),
                )
              else
                OutlinedButton(
                  onPressed: isSelf
                      ? null
                      : () => _run(
                          context,
                          ref,
                          () =>
                              ref.read(adminRepositoryProvider).suspendUser(id),
                          'Account suspended',
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TerravaColors.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    isSelf
                        ? 'You cannot suspend your own account'
                        : 'Suspend account',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<AdminUser> Function() action,
    String success,
  ) async {
    try {
      await action();
      ref.invalidate(adminUserDetailProvider(id));
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException ? error.message : 'Action failed',
            ),
          ),
        );
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: TerravaColors.surfaceContainer,
      side: BorderSide.none,
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TerravaColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: const TextStyle(
                color: TerravaColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
