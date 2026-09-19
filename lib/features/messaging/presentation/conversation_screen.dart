import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/core/theme/terrava_theme.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/messaging/data/messaging_models.dart';
import 'package:terrava/features/messaging/data/messaging_repository.dart';
import 'package:terrava/features/messaging/data/realtime_client.dart';
import 'package:terrava/features/messaging/providers/conversations_provider.dart';

@RoutePage()
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, @PathParam('id') required this.id});

  final String id;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<RealtimeEvent>? _subscription;

  ConversationSummary? _header;
  final List<ChatMessage> _messages = [];
  var _loading = true;
  var _loadingOlder = false;
  var _hasMore = false;
  var _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _subscription = ref.read(realtimeClientProvider).events.listen(_onRealtime);
    await _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final header = await repo.getConversation(widget.id);
      final page = await repo.listMessages(widget.id);
      await repo.markRead(widget.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _header = header.copyWith(unreadCount: 0);
        _messages
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
      });
      ref
          .read(conversationsProvider.notifier)
          .upsert(header.copyWith(unreadCount: 0));
      _jumpToEnd();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error is ApiException ? error.message : error.toString();
      });
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMore || _messages.isEmpty) {
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final page = await ref
          .read(messagingRepositoryProvider)
          .listMessages(widget.id, before: _messages.first.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.insertAll(0, page.items);
        _hasMore = page.hasMore;
        _loadingOlder = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingOlder = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= 48) {
      _loadOlder();
    }
  }

  void _onRealtime(RealtimeEvent event) {
    switch (event) {
      case RealtimeMessageEvent(:final message):
        if (message.conversationId != widget.id) {
          return;
        }
        if (_messages.any((item) => item.id == message.id)) {
          return;
        }
        setState(() => _messages.add(message));
        _jumpToEnd();
        unawaited(ref.read(messagingRepositoryProvider).markRead(widget.id));
      case RealtimeConversationEvent(:final conversation):
        if (conversation.id == widget.id) {
          setState(() => _header = conversation.copyWith(unreadCount: 0));
        }
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      final message = await ref
          .read(messagingRepositoryProvider)
          .sendMessage(conversationId: widget.id, body: body);
      _composer.clear();
      if (!mounted) {
        return;
      }
      if (!_messages.any((item) => item.id == message.id)) {
        setState(() => _messages.add(message));
      }
      _jumpToEnd();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Could not send message',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authSessionProvider).asData?.value;
    final header = _header;

    return Scaffold(
      backgroundColor: TerravaColors.surface,
      appBar: AppBar(
        backgroundColor: TerravaColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: header == null
            ? const Text('Conversation')
            : _ThreadTitle(header: header),
      ),
      body: Column(
        children: [
          if (header != null)
            _ListingStrip(
              header: header,
              onOpenListing: () {
                context.router.push(ListingDetailRoute(id: header.listing.id));
              },
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length + (_loadingOlder ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_loadingOlder && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final messageIndex = _loadingOlder ? index - 1 : index;
                      final message = _messages[messageIndex];
                      final mine = me?.id == message.senderId;
                      return _Bubble(message: message, mine: mine);
                    },
                  ),
          ),
          _Composer(
            controller: _composer,
            sending: _sending,
            enabled: !_loading && _error == null,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ThreadTitle extends StatelessWidget {
  const _ThreadTitle({required this.header});

  final ConversationSummary header;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: header.otherUser.profileImageUrl == null
              ? null
              : CachedNetworkImageProvider(header.otherUser.profileImageUrl!),
          child: header.otherUser.profileImageUrl == null
              ? Text(
                  header.otherUser.name.isNotEmpty
                      ? header.otherUser.name[0].toUpperCase()
                      : '?',
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header.otherUser.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                header.otherUser.verificationStatus == 'VERIFIED'
                    ? 'Verified member'
                    : 'Terrava member',
                style: const TextStyle(
                  fontSize: 12,
                  color: TerravaColors.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListingStrip extends StatelessWidget {
  const _ListingStrip({required this.header, required this.onOpenListing});

  final ConversationSummary header;
  final VoidCallback onOpenListing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TerravaColors.surfaceContainerLow,
      child: InkWell(
        onTap: onOpenListing,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: header.listing.thumbnailUrl == null
                      ? const ColoredBox(
                          color: TerravaColors.surfaceContainerHigh,
                          child: Icon(Icons.home_outlined, size: 20),
                        )
                      : CachedNetworkImage(
                          imageUrl: header.listing.thumbnailUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      header.listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        header.listing.transactionType,
                        if (header.listing.city != null) header.listing.city!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: TerravaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TerravaColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine
                ? TerravaColors.primary
                : TerravaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.body,
                style: TextStyle(
                  color: mine
                      ? TerravaColors.onPrimary
                      : TerravaColors.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatThreadTime(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: mine
                      ? TerravaColors.onPrimary.withValues(alpha: 0.7)
                      : TerravaColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Write an inquiry…',
                  filled: true,
                  fillColor: TerravaColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled && !sending ? onSend : null,
              style: IconButton.styleFrom(
                backgroundColor: TerravaColors.primary,
                foregroundColor: TerravaColors.onPrimary,
                disabledBackgroundColor: TerravaColors.surfaceContainerHigh,
              ),
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
