import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/admin/data/admin_models.dart';
import 'package:terrava/features/admin/providers/admin_providers.dart';

enum _UserFilter { pending, verified, unverified, suspended }

AdminUserQuery _queryFor(_UserFilter filter, String q) {
  final trimmed = q.trim();
  return switch (filter) {
    _UserFilter.pending => AdminUserQuery(
      verificationStatus: 'PENDING',
      q: trimmed.isEmpty ? null : trimmed,
    ),
    _UserFilter.verified => AdminUserQuery(
      verificationStatus: 'VERIFIED',
      q: trimmed.isEmpty ? null : trimmed,
    ),
    _UserFilter.unverified => AdminUserQuery(
      verificationStatus: 'UNVERIFIED',
      q: trimmed.isEmpty ? null : trimmed,
    ),
    _UserFilter.suspended => AdminUserQuery(
      accountStatus: 'SUSPENDED',
      q: trimmed.isEmpty ? null : trimmed,
    ),
  };
}

@RoutePage()
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  _UserFilter _filter = _UserFilter.pending;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryFor(_filter, _search.text);
    final users = ref.watch(adminUsersProvider(query));

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
              ' / Users',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, email, or phone',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: TerravaColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final entry in [
                  (_UserFilter.pending, 'Pending'),
                  (_UserFilter.verified, 'Verified'),
                  (_UserFilter.unverified, 'Unverified'),
                  (_UserFilter.suspended, 'Suspended'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.$2),
                      selected: _filter == entry.$1,
                      onSelected: (_) => setState(() => _filter = entry.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error.toString(), textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(adminUsersProvider(query)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users in this filter.',
                      style: TextStyle(color: TerravaColors.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = page.items[index];
                    return Material(
                      color: TerravaColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        onTap: () => context.router.push(
                          AdminUserDetailRoute(id: user.id),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: TerravaColors.surfaceContainer,
                          backgroundImage: user.profileImageUrl == null
                              ? null
                              : CachedNetworkImageProvider(
                                  user.profileImageUrl!,
                                ),
                          child: user.profileImageUrl == null
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${user.email}\n${verificationLabel(user.verificationStatus)} · ${user.accountStatus}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
