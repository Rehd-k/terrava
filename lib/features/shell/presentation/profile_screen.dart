import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/data/auth_models.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/auth/providers/profile_stats_provider.dart';
import 'package:terrava/features/listings/presentation/create/create_listing_entry.dart';
import 'package:terrava/features/messaging/providers/conversations_provider.dart';
import 'package:terrava/features/saved/providers/saved_listings_provider.dart';

@RoutePage()
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    final bottomInset = 96 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      appBar: AppBar(
        backgroundColor: TerravaColors.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TERRA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: TerravaColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: TerravaColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SignedOutBody(
          title: 'Could not load your session',
          body: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(authSessionProvider),
          bottomInset: bottomInset,
        ),
        data: (user) {
          if (user == null) {
            return _SignedOutBody(
              title: 'Sign in to your profile',
              body:
                  'Listings you own, saved beacons, and inquiry threads stay with your Terrava account.',
              actionLabel: 'Sign in',
              onAction: () async {
                await context.router.push<bool>(const SignInRoute());
              },
              bottomInset: bottomInset,
            );
          }
          return _SignedInProfile(user: user, bottomInset: bottomInset);
        },
      ),
    );
  }
}

class _SignedInProfile extends ConsumerWidget {
  const _SignedInProfile({required this.user, required this.bottomInset});

  final AuthUser user;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider).asData?.value;
    final unread = ref.watch(unreadMessagesCountProvider);
    final savedCount =
        stats?.saved ??
        (ref.watch(savedListingsProvider).asData?.value.length ?? 0);

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 4, 0, bottomInset),
      children: [
        _ProfileHeader(
          user: user,
          onEdit: () => _editProfile(context, ref, user),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _StatsStrip(
            listings: stats?.listings ?? 0,
            live: stats?.live ?? 0,
            inReview: stats?.inReview ?? 0,
            saved: savedCount,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TrustCard(user: user),
        ),
        const SizedBox(height: 20),
        _MenuSection(
          title: 'Property & Activity Hub',
          children: [
            _MenuRow(
              icon: Icons.add_location_alt_outlined,
              title: 'List a property',
              subtitle: 'Pin a new beacon on the discovery map',
              onTap: () => openCreateListing(context, ref),
            ),
            _MenuRow(
              icon: Icons.domain,
              title: 'My Listings',
              subtitle: 'Manage deeds, beacons & architecture',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CountChip(label: '${stats?.listings ?? 0}'),
                  if ((stats?.live ?? 0) > 0) ...[
                    const SizedBox(width: 6),
                    _AccentChip(label: '${stats!.live} Live'),
                  ],
                ],
              ),
              onTap: () => context.router.root.push(const MyListingsRoute()),
            ),
            _MenuRow(
              icon: Icons.favorite,
              title: 'Saved Properties',
              subtitle: 'Curated collection & beacons',
              trailing: _CountChip(label: '$savedCount'),
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(1),
            ),
            _MenuRow(
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              subtitle: 'Direct buyer & inquiry threads',
              trailing: unread > 0
                  ? _PrimaryChip(label: unread > 9 ? '9+' : '$unread new')
                  : null,
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(2),
            ),
            if (user.role == 'ADMIN')
              _MenuRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin',
                subtitle: 'Approve users, listings, and reviews',
                onTap: () => context.router.root.push(const AdminHomeRoute()),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: TerravaColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => ref.read(authSessionProvider.notifier).logout(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      size: 20,
                      color: TerravaColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TerravaColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  AuthUser user,
) async {
  final nameController = TextEditingController(text: user.name);
  final phoneController = TextEditingController(text: user.phone ?? '');
  final formKey = GlobalKey<FormState>();
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TerravaColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => saving = true);
                            try {
                              await ref
                                  .read(authSessionProvider.notifier)
                                  .updateProfile(
                                    name: nameController.text.trim(),
                                    phone: phoneController.text.trim(),
                                  );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            } catch (error) {
                              setSheetState(() => saving = false);
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error is ApiException
                                          ? error.message
                                          : 'Could not update profile',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: TerravaColors.primary,
                      foregroundColor: TerravaColors.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  nameController.dispose();
  phoneController.dispose();
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final AuthUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final year = user.createdAt?.year;
    final verified = user.verificationStatus == 'VERIFIED';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TerravaColors.secondaryFixedDim.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: TerravaColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: user.profileImageUrl == null
                        ? ColoredBox(
                            color: TerravaColors.surfaceContainer,
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: user.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: TerravaColors.surfaceContainer,
                              child: Icon(Icons.person),
                            ),
                          ),
                  ),
                ),
                if (verified)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: TerravaColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 18,
                        color: TerravaColors.onSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            year == null ? user.email : 'Member since $year · ${user.email}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TerravaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: TerravaColors.surfaceContainerLowest,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              onTap: onEdit,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.edit, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatefulWidget {
  const _StatsStrip({
    required this.listings,
    required this.live,
    required this.inReview,
    required this.saved,
  });

  final int listings;
  final int live;
  final int inReview;
  final int saved;

  @override
  State<_StatsStrip> createState() => _StatsStripState();
}

class _StatsStripState extends State<_StatsStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(value: '${widget.listings}', label: 'Listings'),
          ),
          Expanded(
            child: _StatCell(
              value: '${widget.live}',
              label: 'Live Beacon',
              valueColor: TerravaColors.secondary,
              labelColor: TerravaColors.secondary,
              trailing: widget.live > 0
                  ? FadeTransition(
                      opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: TerravaColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: _StatCell(
              value: '${widget.inReview}',
              label: 'In Review',
              valueColor: TerravaColors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _StatCell(value: '${widget.saved}', label: 'Saved'),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.valueColor = TerravaColors.onSurface,
    this.labelColor = TerravaColors.onSurfaceVariant,
    this.trailing,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final verified = user.verificationStatus == 'VERIFIED';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_user : Icons.hourglass_top_outlined,
                size: 20,
                color: verified
                    ? TerravaColors.secondary
                    : TerravaColors.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Account trust',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                verified
                    ? 'Verified'
                    : user.verificationStatus == 'PENDING'
                    ? 'Pending review'
                    : 'Not verified',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: verified
                      ? TerravaColors.secondary
                      : TerravaColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              verified
                  ? 'You can list property and submit beacons for review.'
                  : user.verificationStatus == 'PENDING'
                  ? 'An admin is reviewing your account. You can browse and message while you wait.'
                  : 'An admin must verify your account before you can list a property.',
              style: const TextStyle(
                color: TerravaColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TrustRow(
            icon: Icons.mail,
            title: user.email,
            subtitle: 'Account email',
          ),
          _TrustRow(
            icon: Icons.call,
            title: (user.phone == null || user.phone!.isEmpty)
                ? 'No phone on file'
                : user.phone!,
            subtitle: 'Contact number',
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: TerravaColors.secondaryFixed.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: TerravaColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TerravaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: TerravaColors.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: TerravaColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: TerravaColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: TerravaColors.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TerravaColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: TerravaColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TerravaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  const _AccentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TerravaColors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: TerravaColors.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _PrimaryChip extends StatelessWidget {
  const _PrimaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TerravaColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: TerravaColors.onPrimary,
        ),
      ),
    );
  }
}

class _SignedOutBody extends StatelessWidget {
  const _SignedOutBody({
    required this.title,
    required this.body,
    required this.bottomInset,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final double bottomInset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 36,
              color: TerravaColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TerravaColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: TerravaColors.primary,
                  foregroundColor: TerravaColors.onPrimary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
