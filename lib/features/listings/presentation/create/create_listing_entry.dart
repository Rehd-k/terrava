import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';

Future<void> openCreateListing(
  BuildContext context,
  WidgetRef ref, {
  String? listingId,
}) async {
  var user = ref.read(authSessionProvider).asData?.value;
  if (user == null) {
    final signedIn = await context.router.root.push<bool>(const SignInRoute());
    if (signedIn != true || !context.mounted) return;
    user = ref.read(authSessionProvider).asData?.value;
  }
  if (user == null) return;

  if (user.verificationStatus != 'VERIFIED') {
    if (!context.mounted) return;
    final pending = user.verificationStatus == 'PENDING';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verification required'),
          content: Text(
            pending
                ? 'Your account is waiting for admin verification before you can list a property.'
                : 'An admin needs to verify your account before you can list a property.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return;
  }

  await context.router.root.push(CreateListingRoute(listingId: listingId));
}
