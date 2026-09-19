import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/listings/presentation/create/create_listing_chrome.dart';
import 'package:terrava/features/listings/presentation/create/listing_preview_page.dart';
import 'package:terrava/features/listings/presentation/create/photos_pricing_step.dart';
import 'package:terrava/features/listings/presentation/create/pin_location_step.dart';
import 'package:terrava/features/listings/presentation/create/typology_intent_step.dart';
import 'package:terrava/features/listings/providers/create_listing_controller.dart';
import 'package:terrava/features/listings/providers/my_listings_provider.dart';
import 'package:terrava/features/auth/providers/profile_stats_provider.dart';

@RoutePage()
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({
    super.key,
    @QueryParam('listingId') this.listingId,
  });

  final String? listingId;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(createListingProvider.notifier);
      notifier.reset();
      final id = widget.listingId;
      if (id != null && id.isNotEmpty) {
        await notifier.loadExisting(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingProvider);

    ref.listen(createListingProvider.select((s) => s.error), (_, error) {
      if (error == null || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          CreateListingHeader(onSaveAndExit: _saveAndExit),
          if (state.loadingExisting)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: IndexedStack(
              index: state.step,
              children: [
                const TypologyIntentStep(),
                const PinLocationStep(),
                PhotosPricingStep(onPreview: _openPreview, onSubmit: _submit),
              ],
            ),
          ),
          CreateListingFooter(
            onBack: () => ref.read(createListingProvider.notifier).goBack(),
            onContinue: _continue,
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    final notifier = ref.read(createListingProvider.notifier);
    if (ref.read(createListingProvider).step == 2) {
      await _submit();
      return;
    }
    await notifier.goNext();
  }

  Future<void> _submit() async {
    final ok = await ref.read(createListingProvider.notifier).submit();
    if (!ok || !mounted) return;
    ref.invalidate(myListingsProvider);
    ref.invalidate(profileStatsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Submitted for review')));
    await context.router.maybePop(true);
  }

  Future<void> _saveAndExit() async {
    final notifier = ref.read(createListingProvider.notifier);
    final saved = await notifier.saveAndExit();
    if (!saved) return;
    if (ref.read(createListingProvider).listingId != null) {
      ref.invalidate(myListingsProvider);
      ref.invalidate(profileStatsProvider);
    }
    if (!mounted) return;
    await context.router.maybePop();
  }

  void _openPreview() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ListingPreviewPage()));
  }
}
