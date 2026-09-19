import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/admin/providers/admin_providers.dart';

@RoutePage()
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

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
              ' / Admin',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(adminStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminStatsProvider);
              await ref.read(adminStatsProvider.future);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Text(
                  'Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Verify accounts and review listings before they go live.',
                  style: TextStyle(color: TerravaColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _StatCard(
                      label: 'Pending users',
                      value: data.pendingUsers,
                      icon: Icons.person_outline,
                      onTap: () => context.router.push(const AdminUsersRoute()),
                    ),
                    _StatCard(
                      label: 'Pending listings',
                      value: data.pendingListings,
                      icon: Icons.domain_outlined,
                      onTap: () => context.router.push(AdminListingsRoute()),
                    ),
                    _StatCard(
                      label: 'Live listings',
                      value: data.liveListings,
                      icon: Icons.map_outlined,
                      onTap: () => context.router.push(
                        AdminListingsRoute(status: 'APPROVED'),
                      ),
                    ),
                    _StatCard(
                      label: 'Suspended',
                      value: data.suspendedUsers + data.suspendedListings,
                      icon: Icons.block_outlined,
                      onTap: () => context.router.push(const AdminUsersRoute()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _QueueRow(
                  icon: Icons.verified_user_outlined,
                  title: 'User verification',
                  subtitle: data.pendingUsers == 0
                      ? 'No accounts waiting'
                      : '${data.pendingUsers} waiting for approval',
                  onTap: () => context.router.push(const AdminUsersRoute()),
                ),
                const SizedBox(height: 12),
                _QueueRow(
                  icon: Icons.rate_review_outlined,
                  title: 'Listing review',
                  subtitle: data.pendingListings == 0
                      ? 'Queue is clear'
                      : '${data.pendingListings} submitted for review',
                  onTap: () => context.router.push(AdminListingsRoute()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: TerravaColors.secondary, size: 22),
              const Spacer(),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: TerravaColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: TerravaColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TerravaColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
