import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/admin/data/admin_models.dart';
import 'package:terrava/features/admin/data/admin_repository.dart';
import 'package:terrava/features/admin/providers/admin_providers.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/presentation/listing_detail_view.dart';

@RoutePage()
class AdminListingReviewScreen extends ConsumerWidget {
  const AdminListingReviewScreen({
    super.key,
    @PathParam('id') required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(adminListingDetailProvider(id));

    return listing.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(adminListingDetailProvider(id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (detail) {
        final pending = detail.status == 'PENDING_REVIEW';
        final suspendable =
            detail.status == 'APPROVED' || detail.status == 'PENDING_REVIEW';

        return Scaffold(
          backgroundColor: TerravaColors.background,
          body: SafeArea(
            bottom: false,
            child: ListingDetailView(
              listing: detail,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listingStatusLabel(detail.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: TerravaColors.secondary,
                      ),
                    ),
                    if (detail.reviewNote != null &&
                        detail.reviewNote!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _NoteBanner(note: detail.reviewNote!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: pending || suspendable
              ? _ReviewActions(
                  pending: pending,
                  suspendable: suspendable,
                  onApprove: () => _act(
                    context,
                    ref,
                    () => ref.read(adminRepositoryProvider).approveListing(id),
                    'Listing approved',
                  ),
                  onRequestChanges: () => _noteAction(
                    context,
                    ref,
                    title: 'Request changes',
                    onSubmit: (note) => ref
                        .read(adminRepositoryProvider)
                        .requestChanges(id, note),
                    success: 'Changes requested',
                  ),
                  onReject: () => _noteAction(
                    context,
                    ref,
                    title: 'Reject listing',
                    onSubmit: (note) => ref
                        .read(adminRepositoryProvider)
                        .rejectListing(id, note),
                    success: 'Listing rejected',
                  ),
                  onSuspend: () => _act(
                    context,
                    ref,
                    () => ref.read(adminRepositoryProvider).suspendListing(id),
                    'Listing suspended',
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<ListingDetail> Function() action,
    String success,
  ) async {
    try {
      await action();
      ref.invalidate(adminListingDetailProvider(id));
      ref.invalidate(adminListingsProvider);
      ref.invalidate(adminStatsProvider);
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

  Future<void> _noteAction(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Future<ListingDetail> Function(String note) onSubmit,
    required String success,
  }) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Tell the lister what to change',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length < 3) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (note == null || !context.mounted) return;
    await _act(context, ref, () => onSubmit(note), success);
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TerravaColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(note),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.pending,
    required this.suspendable,
    required this.onApprove,
    required this.onRequestChanges,
    required this.onReject,
    required this.onSuspend,
  });

  final bool pending;
  final bool suspendable;
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;
  final VoidCallback onReject;
  final VoidCallback onSuspend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLowest.withValues(alpha: 0.96),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: TerravaColors.primary,
                          foregroundColor: TerravaColors.onPrimary,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRequestChanges,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Changes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (pending)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TerravaColors.error,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  if (pending && suspendable) const SizedBox(width: 8),
                  if (suspendable)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSuspend,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Suspend'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
