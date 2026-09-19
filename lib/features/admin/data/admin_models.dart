class AdminStats {
  const AdminStats({
    required this.pendingUsers,
    required this.verifiedUsers,
    required this.suspendedUsers,
    required this.pendingListings,
    required this.liveListings,
    required this.suspendedListings,
  });

  final int pendingUsers;
  final int verifiedUsers;
  final int suspendedUsers;
  final int pendingListings;
  final int liveListings;
  final int suspendedListings;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      pendingUsers: json['pendingUsers'] as int? ?? 0,
      verifiedUsers: json['verifiedUsers'] as int? ?? 0,
      suspendedUsers: json['suspendedUsers'] as int? ?? 0,
      pendingListings: json['pendingListings'] as int? ?? 0,
      liveListings: json['liveListings'] as int? ?? 0,
      suspendedListings: json['suspendedListings'] as int? ?? 0,
    );
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.verificationStatus,
    required this.accountStatus,
    required this.role,
    this.createdAt,
    this.listings,
    this.liveListings,
    this.pendingListings,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final String verificationStatus;
  final String accountStatus;
  final String role;
  final DateTime? createdAt;
  final int? listings;
  final int? liveListings;
  final int? pendingListings;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      verificationStatus: json['verificationStatus'] as String,
      accountStatus: json['accountStatus'] as String,
      role: json['role'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String)?.toLocal(),
      listings: json['listings'] as int?,
      liveListings: json['liveListings'] as int?,
      pendingListings: json['pendingListings'] as int?,
    );
  }

  bool get isPending => verificationStatus == 'PENDING';
  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isSuspended => accountStatus == 'SUSPENDED';
  bool get isAdmin => role == 'ADMIN';
}

class PaginatedAdminUsers {
  const PaginatedAdminUsers({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<AdminUser> items;
  final int total;
  final int page;
  final int limit;

  factory PaginatedAdminUsers.fromJson(Map<String, dynamic> json) {
    return PaginatedAdminUsers(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}

class AdminListingSummary {
  const AdminListingSummary({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.transactionType,
    required this.propertyType,
    required this.status,
    this.thumbnailUrl,
    this.address,
    this.city,
    this.state,
    required this.listerId,
    required this.listerName,
    required this.listerEmail,
    this.reviewNote,
    this.submittedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double price;
  final String currency;
  final String transactionType;
  final String propertyType;
  final String status;
  final String? thumbnailUrl;
  final String? address;
  final String? city;
  final String? state;
  final String listerId;
  final String listerName;
  final String listerEmail;
  final String? reviewNote;
  final DateTime? submittedAt;
  final DateTime createdAt;

  factory AdminListingSummary.fromJson(Map<String, dynamic> json) {
    return AdminListingSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      transactionType: json['transactionType'] as String,
      propertyType: json['propertyType'] as String,
      status: json['status'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      listerId: json['listerId'] as String,
      listerName: json['listerName'] as String,
      listerEmail: json['listerEmail'] as String,
      reviewNote: json['reviewNote'] as String?,
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.tryParse(json['submittedAt'] as String)?.toLocal(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  String get locationLabel {
    return [
      address,
      city,
      state,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
  }
}

class PaginatedAdminListings {
  const PaginatedAdminListings({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<AdminListingSummary> items;
  final int total;
  final int page;
  final int limit;

  factory PaginatedAdminListings.fromJson(Map<String, dynamic> json) {
    return PaginatedAdminListings(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => AdminListingSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}

class AdminUserQuery {
  const AdminUserQuery({this.verificationStatus, this.accountStatus, this.q});

  final String? verificationStatus;
  final String? accountStatus;
  final String? q;

  AdminUserQuery copyWith({
    String? verificationStatus,
    String? accountStatus,
    String? q,
    bool clearVerification = false,
    bool clearAccount = false,
    bool clearQ = false,
  }) {
    return AdminUserQuery(
      verificationStatus: clearVerification
          ? null
          : (verificationStatus ?? this.verificationStatus),
      accountStatus: clearAccount
          ? null
          : (accountStatus ?? this.accountStatus),
      q: clearQ ? null : (q ?? this.q),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserQuery &&
          verificationStatus == other.verificationStatus &&
          accountStatus == other.accountStatus &&
          q == other.q;

  @override
  int get hashCode => Object.hash(verificationStatus, accountStatus, q);
}

class AdminListingQuery {
  const AdminListingQuery({this.status, this.all = false, this.q});

  final String? status;
  final bool all;
  final String? q;

  static const pending = AdminListingQuery(status: 'PENDING_REVIEW');

  AdminListingQuery copyWith({
    String? status,
    bool? all,
    String? q,
    bool clearStatus = false,
    bool clearQ = false,
  }) {
    return AdminListingQuery(
      status: clearStatus ? null : (status ?? this.status),
      all: all ?? this.all,
      q: clearQ ? null : (q ?? this.q),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminListingQuery &&
          status == other.status &&
          all == other.all &&
          q == other.q;

  @override
  int get hashCode => Object.hash(status, all, q);
}

String verificationLabel(String status) {
  return switch (status) {
    'VERIFIED' => 'Verified',
    'PENDING' => 'Pending review',
    'UNVERIFIED' => 'Not verified',
    _ => status.replaceAll('_', ' '),
  };
}

String listingStatusLabel(String status) {
  return status.replaceAll('_', ' ');
}
