class MapBounds {
  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  Map<String, dynamic> toQuery() => {
    'minLat': minLat,
    'maxLat': maxLat,
    'minLng': minLng,
    'maxLng': maxLng,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapBounds &&
          minLat == other.minLat &&
          maxLat == other.maxLat &&
          minLng == other.minLng &&
          maxLng == other.maxLng;

  @override
  int get hashCode => Object.hash(minLat, maxLat, minLng, maxLng);
}

class ListingFilters {
  const ListingFilters({
    this.transactionType,
    this.transactionTypes,
    this.propertyType,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.q,
  });

  final String? transactionType;
  final List<String>? transactionTypes;
  final String? propertyType;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final double? bathrooms;
  final String? q;

  static const empty = ListingFilters();

  ListingFilters copyWith({
    String? transactionType,
    List<String>? transactionTypes,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    double? bathrooms,
    String? q,
    bool clearTransactionType = false,
    bool clearTransactionTypes = false,
    bool clearPropertyType = false,
    bool clearQ = false,
  }) {
    return ListingFilters(
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      transactionTypes: clearTransactionTypes
          ? null
          : (transactionTypes ?? this.transactionTypes),
      propertyType: clearPropertyType
          ? null
          : (propertyType ?? this.propertyType),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      q: clearQ ? null : (q ?? this.q),
    );
  }

  Map<String, dynamic> toQuery() {
    return {
      if (transactionType != null) 'transactionType': transactionType,
      if (transactionTypes != null && transactionTypes!.isNotEmpty)
        'transactionTypes': transactionTypes!.join(','),
      if (propertyType != null) 'propertyType': propertyType,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingFilters &&
          transactionType == other.transactionType &&
          _listEq(transactionTypes, other.transactionTypes) &&
          propertyType == other.propertyType &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          bedrooms == other.bedrooms &&
          bathrooms == other.bathrooms &&
          q == other.q;

  @override
  int get hashCode => Object.hash(
    transactionType,
    Object.hashAll(transactionTypes ?? const []),
    propertyType,
    minPrice,
    maxPrice,
    bedrooms,
    bathrooms,
    q,
  );
}

bool _listEq(List<String>? a, List<String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class MapListingPin {
  const MapListingPin({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.transactionType,
    this.pricePeriod,
    required this.propertyType,
    required this.latitude,
    required this.longitude,
    this.thumbnailUrl,
    this.landSize,
    this.propertySize,
    this.city,
  });

  final String id;
  final String title;
  final double price;
  final String currency;
  final String transactionType;
  final String? pricePeriod;
  final String propertyType;
  final double latitude;
  final double longitude;
  final String? thumbnailUrl;
  final double? landSize;
  final double? propertySize;
  final String? city;

  factory MapListingPin.fromJson(Map<String, dynamic> json) {
    return MapListingPin(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      transactionType: json['transactionType'] as String,
      pricePeriod: json['pricePeriod'] as String?,
      propertyType: json['propertyType'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      landSize: (json['landSize'] as num?)?.toDouble(),
      propertySize: (json['propertySize'] as num?)?.toDouble(),
      city: json['city'] as String?,
    );
  }
}

class ListingMedia {
  const ListingMedia({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.mediaType,
    required this.sortOrder,
  });

  final String id;
  final String url;
  final String? thumbnailUrl;
  final String mediaType;
  final int sortOrder;

  factory ListingMedia.fromJson(Map<String, dynamic> json) {
    return ListingMedia(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediaType: json['mediaType'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }
}

class ListingProperty {
  const ListingProperty({
    required this.id,
    required this.type,
    this.address,
    this.city,
    this.state,
    this.country,
    required this.latitude,
    required this.longitude,
    this.propertySize,
    this.landSize,
    this.bedrooms,
    this.bathrooms,
    this.description,
    required this.amenities,
  });

  final String id;
  final String type;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double latitude;
  final double longitude;
  final double? propertySize;
  final double? landSize;
  final int? bedrooms;
  final double? bathrooms;
  final String? description;
  final List<String> amenities;

  factory ListingProperty.fromJson(Map<String, dynamic> json) {
    return ListingProperty(
      id: json['id'] as String,
      type: json['type'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      propertySize: (json['propertySize'] as num?)?.toDouble(),
      landSize: (json['landSize'] as num?)?.toDouble(),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: (json['bathrooms'] as num?)?.toDouble(),
      description: json['description'] as String?,
      amenities: (json['amenities'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ListingLister {
  const ListingLister({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.verificationStatus,
  });

  final String id;
  final String name;
  final String? profileImageUrl;
  final String verificationStatus;

  factory ListingLister.fromJson(Map<String, dynamic> json) {
    return ListingLister(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      verificationStatus: json['verificationStatus'] as String,
    );
  }
}

class ListingDetail {
  const ListingDetail({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.agencyFee,
    this.legalFee,
    required this.currency,
    required this.transactionType,
    this.listedBy = 'OWNER',
    this.pricePeriod = 'ONE_OFF',
    required this.listingType,
    required this.status,
    required this.property,
    required this.media,
    required this.lister,
    this.reviewNote,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final double price;
  final double? agencyFee;
  final double? legalFee;
  final String currency;
  final String transactionType;
  final String listedBy;
  final String pricePeriod;
  final String listingType;
  final String status;
  final ListingProperty property;
  final List<ListingMedia> media;
  final ListingLister lister;
  final String? reviewNote;
  final DateTime? createdAt;

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    return ListingDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      agencyFee: (json['agencyFee'] as num?)?.toDouble(),
      legalFee: (json['legalFee'] as num?)?.toDouble(),
      currency: json['currency'] as String,
      transactionType: json['transactionType'] as String,
      listedBy: json['listedBy'] as String? ?? 'OWNER',
      pricePeriod:
          json['pricePeriod'] as String? ??
          ((json['transactionType'] == 'RENT' ||
                  json['transactionType'] == 'LEASE')
              ? 'PER_YEAR'
              : 'ONE_OFF'),
      listingType: json['listingType'] as String,
      status: json['status'] as String,
      property: ListingProperty.fromJson(
        json['property'] as Map<String, dynamic>,
      ),
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((e) => ListingMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      lister: ListingLister.fromJson(json['lister'] as Map<String, dynamic>),
      reviewNote: json['reviewNote'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String)?.toLocal(),
    );
  }

  double get totalDue => price + (agencyFee ?? 0) + (legalFee ?? 0);

  bool get isRecurring =>
      pricePeriod == 'PER_YEAR' ||
      transactionType == 'RENT' ||
      transactionType == 'LEASE';

  String? get heroImageUrl {
    for (final item in media) {
      if (item.mediaType == 'IMAGE') {
        return item.url;
      }
    }
    return media.isEmpty ? null : media.first.url;
  }
}

class OwnerListing {
  const OwnerListing({
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
    this.landSize,
    this.propertySize,
    required this.createdAt,
    this.submittedAt,
    this.reviewNote,
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
  final double? landSize;
  final double? propertySize;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final String? reviewNote;

  factory OwnerListing.fromJson(Map<String, dynamic> json) {
    return OwnerListing(
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
      landSize: (json['landSize'] as num?)?.toDouble(),
      propertySize: (json['propertySize'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.tryParse(json['submittedAt'] as String)?.toLocal(),
      reviewNote: json['reviewNote'] as String?,
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
