class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.verificationStatus,
    required this.accountStatus,
    required this.role,
    this.createdAt,
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

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
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
    );
  }
}

class UserStats {
  const UserStats({
    required this.listings,
    required this.live,
    required this.inReview,
    required this.saved,
  });

  final int listings;
  final int live;
  final int inReview;
  final int saved;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      listings: json['listings'] as int? ?? 0,
      live: json['live'] as int? ?? 0,
      inReview: json['inReview'] as int? ?? 0,
      saved: json['saved'] as int? ?? 0,
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
