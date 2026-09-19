// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AdminHomeScreen]
class AdminHomeRoute extends PageRouteInfo<void> {
  const AdminHomeRoute({List<PageRouteInfo>? children})
    : super(AdminHomeRoute.name, initialChildren: children);

  static const String name = 'AdminHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminHomeScreen();
    },
  );
}

/// generated route for
/// [AdminListingReviewScreen]
class AdminListingReviewRoute
    extends PageRouteInfo<AdminListingReviewRouteArgs> {
  AdminListingReviewRoute({
    Key? key,
    required String id,
    List<PageRouteInfo>? children,
  }) : super(
         AdminListingReviewRoute.name,
         args: AdminListingReviewRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'AdminListingReviewRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AdminListingReviewRouteArgs>(
        orElse: () =>
            AdminListingReviewRouteArgs(id: pathParams.getString('id')),
      );
      return AdminListingReviewScreen(key: args.key, id: args.id);
    },
  );
}

class AdminListingReviewRouteArgs {
  const AdminListingReviewRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'AdminListingReviewRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdminListingReviewRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [AdminListingsScreen]
class AdminListingsRoute extends PageRouteInfo<AdminListingsRouteArgs> {
  AdminListingsRoute({Key? key, String? status, List<PageRouteInfo>? children})
    : super(
        AdminListingsRoute.name,
        args: AdminListingsRouteArgs(key: key, status: status),
        rawQueryParams: {'status': status},
        initialChildren: children,
      );

  static const String name = 'AdminListingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AdminListingsRouteArgs>(
        orElse: () =>
            AdminListingsRouteArgs(status: queryParams.optString('status')),
      );
      return AdminListingsScreen(key: args.key, status: args.status);
    },
  );
}

class AdminListingsRouteArgs {
  const AdminListingsRouteArgs({this.key, this.status});

  final Key? key;

  final String? status;

  @override
  String toString() {
    return 'AdminListingsRouteArgs{key: $key, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdminListingsRouteArgs) return false;
    return key == other.key && status == other.status;
  }

  @override
  int get hashCode => key.hashCode ^ status.hashCode;
}

/// generated route for
/// [AdminUserDetailScreen]
class AdminUserDetailRoute extends PageRouteInfo<AdminUserDetailRouteArgs> {
  AdminUserDetailRoute({
    Key? key,
    required String id,
    List<PageRouteInfo>? children,
  }) : super(
         AdminUserDetailRoute.name,
         args: AdminUserDetailRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'AdminUserDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AdminUserDetailRouteArgs>(
        orElse: () => AdminUserDetailRouteArgs(id: pathParams.getString('id')),
      );
      return AdminUserDetailScreen(key: args.key, id: args.id);
    },
  );
}

class AdminUserDetailRouteArgs {
  const AdminUserDetailRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'AdminUserDetailRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdminUserDetailRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [AdminUsersScreen]
class AdminUsersRoute extends PageRouteInfo<void> {
  const AdminUsersRoute({List<PageRouteInfo>? children})
    : super(AdminUsersRoute.name, initialChildren: children);

  static const String name = 'AdminUsersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminUsersScreen();
    },
  );
}

/// generated route for
/// [ConversationScreen]
class ConversationRoute extends PageRouteInfo<ConversationRouteArgs> {
  ConversationRoute({
    Key? key,
    required String id,
    List<PageRouteInfo>? children,
  }) : super(
         ConversationRoute.name,
         args: ConversationRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'ConversationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ConversationRouteArgs>(
        orElse: () => ConversationRouteArgs(id: pathParams.getString('id')),
      );
      return ConversationScreen(key: args.key, id: args.id);
    },
  );
}

class ConversationRouteArgs {
  const ConversationRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'ConversationRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConversationRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [CreateListingScreen]
class CreateListingRoute extends PageRouteInfo<CreateListingRouteArgs> {
  CreateListingRoute({
    Key? key,
    String? listingId,
    List<PageRouteInfo>? children,
  }) : super(
         CreateListingRoute.name,
         args: CreateListingRouteArgs(key: key, listingId: listingId),
         rawQueryParams: {'listingId': listingId},
         initialChildren: children,
       );

  static const String name = 'CreateListingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<CreateListingRouteArgs>(
        orElse: () => CreateListingRouteArgs(
          listingId: queryParams.optString('listingId'),
        ),
      );
      return CreateListingScreen(key: args.key, listingId: args.listingId);
    },
  );
}

class CreateListingRouteArgs {
  const CreateListingRouteArgs({this.key, this.listingId});

  final Key? key;

  final String? listingId;

  @override
  String toString() {
    return 'CreateListingRouteArgs{key: $key, listingId: $listingId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CreateListingRouteArgs) return false;
    return key == other.key && listingId == other.listingId;
  }

  @override
  int get hashCode => key.hashCode ^ listingId.hashCode;
}

/// generated route for
/// [ListingDetailScreen]
class ListingDetailRoute extends PageRouteInfo<ListingDetailRouteArgs> {
  ListingDetailRoute({
    Key? key,
    required String id,
    List<PageRouteInfo>? children,
  }) : super(
         ListingDetailRoute.name,
         args: ListingDetailRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'ListingDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ListingDetailRouteArgs>(
        orElse: () => ListingDetailRouteArgs(id: pathParams.getString('id')),
      );
      return ListingDetailScreen(key: args.key, id: args.id);
    },
  );
}

class ListingDetailRouteArgs {
  const ListingDetailRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'ListingDetailRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListingDetailRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [MainShellScreen]
class MainShellRoute extends PageRouteInfo<void> {
  const MainShellRoute({List<PageRouteInfo>? children})
    : super(MainShellRoute.name, initialChildren: children);

  static const String name = 'MainShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainShellScreen();
    },
  );
}

/// generated route for
/// [MapHomeScreen]
class MapHomeRoute extends PageRouteInfo<void> {
  const MapHomeRoute({List<PageRouteInfo>? children})
    : super(MapHomeRoute.name, initialChildren: children);

  static const String name = 'MapHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MapHomeScreen();
    },
  );
}

/// generated route for
/// [MessagesScreen]
class MessagesRoute extends PageRouteInfo<void> {
  const MessagesRoute({List<PageRouteInfo>? children})
    : super(MessagesRoute.name, initialChildren: children);

  static const String name = 'MessagesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MessagesScreen();
    },
  );
}

/// generated route for
/// [MyListingsScreen]
class MyListingsRoute extends PageRouteInfo<void> {
  const MyListingsRoute({List<PageRouteInfo>? children})
    : super(MyListingsRoute.name, initialChildren: children);

  static const String name = 'MyListingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MyListingsScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [SavedScreen]
class SavedRoute extends PageRouteInfo<void> {
  const SavedRoute({List<PageRouteInfo>? children})
    : super(SavedRoute.name, initialChildren: children);

  static const String name = 'SavedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SavedScreen();
    },
  );
}

/// generated route for
/// [SignInScreen]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
    : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignInScreen();
    },
  );
}
