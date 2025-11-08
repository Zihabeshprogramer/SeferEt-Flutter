/// Unified model for featured products (flights, hotels, packages)
class FeaturedProduct {
  final String id;
  final String type; // 'flight', 'hotel', 'package'
  final String title;
  final String? shortDesc;
  final String? imageUrl;
  final double price;
  final String currency;
  final String source; // 'local', 'amadeus'
  final Map<String, dynamic>? metadata; // Extra data specific to type
  final double? rating;
  final int? reviewCount;
  final String? location;
  final String? badge; // e.g., "Featured", "Popular", "Best Deal"

  FeaturedProduct({
    required this.id,
    required this.type,
    required this.title,
    this.shortDesc,
    this.imageUrl,
    required this.price,
    required this.currency,
    required this.source,
    this.metadata,
    this.rating,
    this.reviewCount,
    this.location,
    this.badge,
  });

  factory FeaturedProduct.fromJson(Map<String, dynamic> json) {
    return FeaturedProduct(
      id: json['id'].toString(),
      type: json['type'] as String,
      title: json['title'] as String,
      shortDesc: json['short_desc'] as String? ?? json['description'] as String?,
      imageUrl: json['image_url'] as String? ?? json['image'] as String?,
      price: _parsePrice(json['price']),
      currency: json['currency'] as String? ?? 'USD',
      source: json['source'] as String? ?? 'local',
      metadata: json['metadata'] as Map<String, dynamic>?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      location: json['location'] as String?,
      badge: json['badge'] as String?,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is Map) {
      // Handle nested price object
      final amount = price['amount'] ?? price['total'];
      if (amount != null) {
        if (amount is num) return amount.toDouble();
        if (amount is String) return double.tryParse(amount) ?? 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'short_desc': shortDesc,
      'image_url': imageUrl,
      'price': price,
      'currency': currency,
      'source': source,
      'metadata': metadata,
      'rating': rating,
      'review_count': reviewCount,
      'location': location,
      'badge': badge,
    };
  }

  String get priceFormatted => '$currency ${price.toStringAsFixed(2)}';

  bool get isLocal => source == 'local';
  bool get isAmadeus => source == 'amadeus';

  String get typeLabel {
    switch (type) {
      case 'flight':
        return 'Flight';
      case 'hotel':
        return 'Hotel';
      case 'package':
        return 'Package';
      default:
        return type;
    }
  }
}

/// Recommendation model with personalization context
class Recommendation {
  final String id;
  final String type;
  final String title;
  final String? imageUrl;
  final double price;
  final String currency;
  final String source;
  final String reasonTag; // e.g., "Because you booked X", "Popular in your city"
  final double? rating;
  final String? location;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    this.imageUrl,
    required this.price,
    required this.currency,
    required this.source,
    required this.reasonTag,
    this.rating,
    this.location,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'].toString(),
      type: json['type'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String? ?? json['image'] as String?,
      price: FeaturedProduct._parsePrice(json['price']),
      currency: json['currency'] as String? ?? 'USD',
      source: json['source'] as String? ?? 'local',
      reasonTag: json['reason_tag'] as String? ?? json['reason'] as String? ?? 'Recommended for you',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'image_url': imageUrl,
      'price': price,
      'currency': currency,
      'source': source,
      'reason_tag': reasonTag,
      'rating': rating,
      'location': location,
    };
  }

  String get priceFormatted => '$currency ${price.toStringAsFixed(2)}';

  /// Convert to FeaturedProduct for unified display
  FeaturedProduct toFeaturedProduct() {
    return FeaturedProduct(
      id: id,
      type: type,
      title: title,
      imageUrl: imageUrl,
      price: price,
      currency: currency,
      source: source,
      rating: rating,
      location: location,
      badge: reasonTag,
    );
  }
}
