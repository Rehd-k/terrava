import 'dart:math' as math;

String currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'NGN':
      return '₦';
    case 'USD':
      return '\$';
    default:
      return '$currency ';
  }
}

bool isRecurringPrice({required String transactionType, String? pricePeriod}) {
  if (pricePeriod == 'PER_YEAR') return true;
  if (pricePeriod == 'ONE_OFF') return false;
  return transactionType == 'RENT' || transactionType == 'LEASE';
}

String formatCompactAmount(double price, String currency) {
  final symbol = currencySymbol(currency);
  if (price >= 1000000) {
    return '$symbol${_trimDecimal(price / 1000000)}M';
  }
  if (price >= 1000) {
    return '$symbol${_trimDecimal(price / 1000)}k';
  }
  return '$symbol${commas(price.round())}';
}

String _trimDecimal(double value) {
  if ((value - value.roundToDouble()).abs() < 0.0001) {
    return value.round().toString();
  }
  final two = value.toStringAsFixed(2);
  if (two.endsWith('0')) {
    final one = value.toStringAsFixed(1);
    if (one.endsWith('.0')) return value.round().toString();
    return one;
  }
  return two;
}

String formatListingPrice({
  required double price,
  required String currency,
  required String transactionType,
  String? pricePeriod,
  String? propertyType,
  double? landSize,
}) {
  final compact = formatCompactAmount(price, currency);
  final recurring = isRecurringPrice(
    transactionType: transactionType,
    pricePeriod: pricePeriod,
  );
  var label = recurring ? '$compact/yr' : compact;
  if (propertyType == 'LAND' && landSize != null && landSize > 0) {
    label = '$label · ${formatLandSize(landSize, short: true)}';
  }
  return label;
}

String formatFullPrice({
  required double price,
  required String currency,
  String? pricePeriod,
  String? transactionType,
}) {
  final symbol = currencySymbol(currency);
  final amount = '$symbol${commas(price.round())}';
  final recurring = isRecurringPrice(
    transactionType: transactionType ?? 'SALE',
    pricePeriod: pricePeriod,
  );
  return recurring ? '$amount/yr' : amount;
}

String formatLandSize(double sqm, {bool short = false}) {
  const plotSqm = 465.0;
  final plots = sqm / plotSqm;
  final wholePlots = plots.roundToDouble();
  final isWhole = (plots - wholePlots).abs() < 0.08;
  if (isWhole && wholePlots >= 1) {
    final count = wholePlots.round();
    if (short) {
      return count == 1 ? '1 plot' : '$count plots';
    }
    return count == 1
        ? '1 plot · ${commas(sqm.round())} sqm'
        : '$count plots · ${commas(sqm.round())} sqm';
  }
  return '${commas(sqm.round())} sqm';
}

String formatInteriorSize(double sqm) => '${commas(sqm.round())} sqm';

String transactionLabel(String transactionType) {
  switch (transactionType) {
    case 'SALE':
      return 'For Sale';
    case 'RENT':
      return 'Rental';
    case 'LEASE':
      return 'Lease';
    default:
      return transactionType;
  }
}

String propertyTypeLabel(String propertyType) {
  switch (propertyType) {
    case 'LAND':
      return 'Land';
    case 'HOUSE':
      return 'House';
    case 'APARTMENT':
      return 'Apartment';
    case 'ROOM':
      return 'Room';
    case 'COMMERCIAL':
      return 'Commercial';
    default:
      return propertyType;
  }
}

String listedByLabel(String listedBy) {
  switch (listedBy) {
    case 'AGENT':
      return 'Listed by agent';
    case 'TENANT':
      return 'Listed by existing tenant';
    case 'OWNER':
    default:
      return 'Directly by owner';
  }
}

String pricePeriodLabel(String pricePeriod, {required String transactionType}) {
  if (pricePeriod == 'PER_YEAR' ||
      transactionType == 'RENT' ||
      transactionType == 'LEASE') {
    return 'Per year';
  }
  return 'One-off';
}

String formatDistanceFromUser({
  required double listingLat,
  required double listingLng,
  double? userLat,
  double? userLng,
}) {
  if (userLat == null || userLng == null) {
    return 'Turn on location to see distance';
  }
  final meters = haversineMeters(userLat, userLng, listingLat, listingLng);
  if (meters < 1000) {
    return '${meters.round()} m from you';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km from you';
}

String formatListedAgo(DateTime? createdAt) {
  if (createdAt == null) return 'Recently listed';
  final days = DateTime.now().difference(createdAt).inDays;
  if (days <= 0) return 'Listed today';
  if (days == 1) return 'Listed 1 day ago';
  if (days < 30) return 'Listed $days days ago';
  final months = (days / 30).floor();
  return months == 1 ? 'Listed 1 month ago' : 'Listed $months months ago';
}

String commas(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRadians(double deg) => deg * math.pi / 180;
