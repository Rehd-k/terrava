import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/messaging/data/messaging_models.dart';
import 'package:terrava/features/messaging/providers/conversations_provider.dart';

@RoutePage()
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    final conversations = ref.watch(conversationsProvider);
    final bottomInset = 88 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      appBar: AppBar(
        backgroundColor: TerravaColors.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Messages',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StatusBody(
          title: 'Could not load your session',
          body: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(authSessionProvider),
          bottomInset: bottomInset,
        ),
        data: (user) {
          if (user == null) {
            return _StatusBody(
              title: 'Sign in to message listers',
              body:
                  'Inquiry threads about listings live here — availability, showings, and deed questions in one place.',
              actionLabel: 'Sign in',
              onAction: () async {
                final signedIn = await context.router.push<bool>(
                  const SignInRoute(),
                );
                if (signedIn == true) {
                  await ref.read(conversationsProvider.notifier).refresh();
                }
              },
              bottomInset: bottomInset,
            );
          }

          return conversations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _StatusBody(
              title: 'Conversations unavailable',
              body: error.toString(),
              actionLabel: 'Retry',
              onAction: () =>
                  ref.read(conversationsProvider.notifier).refresh(),
              bottomInset: bottomInset,
            ),
            data: (items) {
              if (items.isEmpty) {
                return _StatusBody(
                  title: 'No inquiry threads yet',
                  body:
                      'Open a listing and message the lister to start a conversation.',
                  bottomInset: bottomInset,
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conversation = items[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () {
                        context.router.root.push(
                          ConversationRoute(id: conversation.id),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    final preview =
        conversation.lastMessage?.body ??
        'Inquiry about ${conversation.listing.title}';
    final time = conversation.lastMessageAt ?? conversation.createdAt;

    return Material(
      color: TerravaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Avatar(
                imageUrl:
                    conversation.otherUser.profileImageUrl ??
                    conversation.listing.thumbnailUrl,
                label: conversation.otherUser.name,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatThreadTime(time),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: unread
                                ? TerravaColors.secondary
                                : TerravaColors.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TerravaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                        color: unread
                            ? TerravaColors.onSurface
                            : TerravaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TerravaColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    conversation.unreadCount > 9
                        ? '9+'
                        : '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: TerravaColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl == null
            ? ColoredBox(
                color: TerravaColors.surfaceContainerHigh,
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(
                  color: TerravaColors.surfaceContainerHigh,
                  child: Center(child: Text(initial)),
                ),
              ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
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
              Icons.chat_bubble_outline,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
