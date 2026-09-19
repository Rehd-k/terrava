import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/listings/providers/create_listing_controller.dart';

const _stepTitles = [
  'Step 1: Property Basics',
  'Step 2: Location & Pin',
  'Step 3: Pricing & Review',
];

class CreateListingHeader extends ConsumerWidget {
  const CreateListingHeader({super.key, required this.onSaveAndExit});

  final VoidCallback onSaveAndExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(createListingProvider.select((s) => s.step));
    final user = ref.watch(authSessionProvider).asData?.value;
    final progress = (step + 1) / 3;

    return Material(
      color: TerravaColors.surface.withValues(alpha: 0.86),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onSaveAndExit,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Save & Exit'),
                  style: TextButton.styleFrom(
                    foregroundColor: TerravaColors.onSurfaceVariant,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _stepTitles[step],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: TerravaColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: TerravaColors.primary,
                  backgroundImage: user?.profileImageUrl == null
                      ? null
                      : CachedNetworkImageProvider(user!.profileImageUrl!),
                  child: user?.profileImageUrl == null
                      ? Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: TerravaColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: TerravaColors.surfaceContainerHighest,
                color: TerravaColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateListingFooter extends ConsumerWidget {
  const CreateListingFooter({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createListingProvider);
    final isLast = state.step == 2;
    final busy = state.saving || state.submitting;

    return Material(
      color: TerravaColors.surface.withValues(alpha: 0.92),
      elevation: 8,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          children: [
            SizedBox(
              height: 48,
              child: FilledButton.tonal(
                onPressed: state.step == 0 || busy ? null : onBack,
                style: FilledButton.styleFrom(
                  backgroundColor: TerravaColors.surfaceContainerHigh,
                  foregroundColor: TerravaColors.onSurface,
                  disabledBackgroundColor: TerravaColors.surfaceContainer,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 6),
                    Text('Back'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: busy ? null : onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: TerravaColors.primary,
                    foregroundColor: TerravaColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLast ? 'Submit for review' : 'Continue'),
                            const SizedBox(width: 6),
                            Icon(
                              isLast ? Icons.check : Icons.arrow_forward,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
