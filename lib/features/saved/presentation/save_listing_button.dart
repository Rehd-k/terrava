import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/saved/providers/saved_listings_provider.dart';

class SaveListingButton extends ConsumerStatefulWidget {
  const SaveListingButton({
    super.key,
    required this.listingId,
    this.foregroundColor,
  });

  final String listingId;
  final Color? foregroundColor;

  @override
  ConsumerState<SaveListingButton> createState() => _SaveListingButtonState();
}

class _SaveListingButtonState extends ConsumerState<SaveListingButton> {
  bool? _optimistic;

  @override
  Widget build(BuildContext context) {
    final saved =
        _optimistic ??
        ref.watch(savedListingIdsProvider).contains(widget.listingId);
    return IconButton(
      tooltip: saved ? 'Remove from saved' : 'Save listing',
      onPressed: () => _toggle(saved),
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        color: saved
            ? TerravaColors.error
            : (widget.foregroundColor ?? TerravaColors.onSurface),
      ),
    );
  }

  Future<void> _toggle(bool currentlySaved) async {
    var user = ref.read(authSessionProvider).asData?.value;
    if (user == null) {
      final signedIn = await context.router.push<bool>(const SignInRoute());
      if (signedIn != true) return;
      user = ref.read(authSessionProvider).asData?.value;
      if (user == null) return;
      await ref.read(savedListingsProvider.notifier).refresh();
      currentlySaved = ref
          .read(savedListingIdsProvider)
          .contains(widget.listingId);
    }

    setState(() => _optimistic = !currentlySaved);
    try {
      final notifier = ref.read(savedListingsProvider.notifier);
      if (currentlySaved) {
        await notifier.unsave(widget.listingId);
      } else {
        await notifier.save(widget.listingId);
      }
      if (mounted) {
        setState(() => _optimistic = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _optimistic = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Could not update saved listing',
            ),
          ),
        );
      }
    }
  }
}
