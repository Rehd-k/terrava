import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/router/app_router.dart';
import 'package:terrava/features/messaging/providers/conversations_provider.dart';
import 'package:terrava/features/shell/presentation/terrava_bottom_nav.dart';

@RoutePage()
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadMessagesCountProvider);
    return AutoTabsRouter(
      routes: const [
        MapHomeRoute(),
        SavedRoute(),
        MessagesRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: Stack(
            children: [
              child,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TerravaBottomNav(
                  activeIndex: tabsRouter.activeIndex,
                  messagesBadge: unread,
                  onTap: tabsRouter.setActiveIndex,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
