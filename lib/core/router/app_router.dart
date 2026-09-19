import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:terrava/features/admin/presentation/admin_home_screen.dart';
import 'package:terrava/features/admin/presentation/admin_listing_review_screen.dart';
import 'package:terrava/features/admin/presentation/admin_listings_screen.dart';
import 'package:terrava/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:terrava/features/admin/presentation/admin_users_screen.dart';
import 'package:terrava/features/auth/presentation/sign_in_screen.dart';
import 'package:terrava/features/listings/presentation/create/create_listing_screen.dart';
import 'package:terrava/features/listings/presentation/listing_detail_screen.dart';
import 'package:terrava/features/listings/presentation/my_listings_screen.dart';
import 'package:terrava/features/map/presentation/map_home_screen.dart';
import 'package:terrava/features/messaging/presentation/conversation_screen.dart';
import 'package:terrava/features/messaging/presentation/messages_screen.dart';
import 'package:terrava/features/shell/presentation/main_shell_screen.dart';
import 'package:terrava/features/shell/presentation/profile_screen.dart';
import 'package:terrava/features/shell/presentation/saved_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: MainShellRoute.page,
      initial: true,
      children: [
        AutoRoute(page: MapHomeRoute.page, initial: true),
        AutoRoute(page: SavedRoute.page),
        AutoRoute(page: MessagesRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
    AutoRoute(page: ListingDetailRoute.page, path: '/listings/:id'),
    AutoRoute(page: ConversationRoute.page, path: '/conversations/:id'),
    AutoRoute(page: SignInRoute.page),
    AutoRoute(page: MyListingsRoute.page),
    AutoRoute(page: CreateListingRoute.page, path: '/list-property'),
    AutoRoute(page: AdminHomeRoute.page, path: '/admin'),
    AutoRoute(page: AdminUsersRoute.page, path: '/admin/users'),
    AutoRoute(page: AdminUserDetailRoute.page, path: '/admin/users/:id'),
    AutoRoute(page: AdminListingsRoute.page, path: '/admin/listings'),
    AutoRoute(page: AdminListingReviewRoute.page, path: '/admin/listings/:id'),
  ];
}
