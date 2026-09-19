class SavedListing {
  const SavedListing({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.transactionType,
    required this.propertyType,
    required this.latitude,
    required this.longitude,
    this.thumbnailUrl,
    this.city,
    this.landSize,
    this.propertySize,
    required this.savedAt,
  });

  final String id;
  final String title;
  final double price;
  final String currency;
  final String transactionType;
  final String propertyType;
  final double latitude;
  final double longitude;
  final String? thumbnailUrl;
  final String? city;
  final double? landSize;
  final double? propertySize;
  final DateTime savedAt;

  factory SavedListing.fromJson(Map<String, dynamic> json) {
    return SavedListing(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      transactionType: json['transactionType'] as String,
      propertyType: json['propertyType'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      city: json['city'] as String?,
      landSize: (json['landSize'] as num?)?.toDouble(),
      propertySize: (json['propertySize'] as num?)?.toDouble(),
      savedAt: DateTime.parse(json['savedAt'] as String).toLocal(),
    );
  }
}
