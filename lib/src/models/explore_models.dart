import 'package:flutter/material.dart';
import 'package:seferet_flutter/src/models/package.dart';
import 'package:seferet_flutter/src/models/hotel_models.dart';

/// Product types available in Explore View
enum ProductType {
  packages,
  hotels,
  flights,
}

extension ProductTypeExtension on ProductType {
  String get label {
    switch (this) {
      case ProductType.packages:
        return 'Packages';
      case ProductType.hotels:
        return 'Hotels';
      case ProductType.flights:
        return 'Flights';
    }
  }

  String get singular {
    switch (this) {
      case ProductType.packages:
        return 'Package';
      case ProductType.hotels:
        return 'Hotel';
      case ProductType.flights:
        return 'Flight';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductType.packages:
        return Icons.mosque;
      case ProductType.hotels:
        return Icons.hotel;
      case ProductType.flights:
        return Icons.flight;
    }
  }

  Color get accentColor {
    switch (this) {
      case ProductType.packages:
        return const Color(0xFF4CAF50); // Green for Umrah/Hajj
      case ProductType.hotels:
        return const Color(0xFF2196F3); // Blue for Hotels
      case ProductType.flights:
        return const Color(0xFFFF9800); // Orange for Flights
    }
  }
}

/// Unified explore item that can represent any product type
class ExploreItem {
  final String id;
  final ProductType type;
  final String name;
  final String? imageUrl;
  final double? price;
  final String? currency;
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;
  final String? location;
  final String? duration;
  final String? subtitle;
  final bool isFeatured;
  final bool hasDiscount;
  final Map<String, dynamic>? metadata;

  ExploreItem({
    required this.id,
    required this.type,
    required this.name,
    this.imageUrl,
    this.price,
    this.currency,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.location,
    this.duration,
    this.subtitle,
    this.isFeatured = false,
    this.hasDiscount = false,
    this.metadata,
  });

  /// Create from Package model
  factory ExploreItem.fromPackage(Package package) {
    return ExploreItem(
      id: package.id.toString(),
      type: ProductType.packages,
      name: package.name,
      imageUrl: package.mainImageUrl,
      price: package.displayPrice,
      currency: package.currency,
      originalPrice: package.hasDiscount ? package.basePrice : null,
      rating: package.rating.average,
      reviewCount: package.rating.count,
      location: package.destinations.isNotEmpty ? package.destinations.first : null,
      duration: package.durationFormatted,
      subtitle: package.typeLabel,
      isFeatured: package.isFeatured,
      hasDiscount: package.hasDiscount,
      metadata: {
        'slug': package.slug,
        'package': package,
      },
    );
  }

  /// Create from Hotel model
  factory ExploreItem.fromHotel(Hotel hotel) {
    final lowestPrice = hotel.lowestPrice;
    return ExploreItem(
      id: hotel.id,
      type: ProductType.hotels,
      name: hotel.name,
      imageUrl: hotel.imageUrl,
      price: lowestPrice,
      currency: hotel.offers?.first.currency ?? 'USD',
      rating: hotel.guestRating ?? hotel.rating.toDouble(),
      reviewCount: hotel.reviewCount,
      location: hotel.displayLocation,
      subtitle: '${hotel.rating}★ Hotel${hotel.source == 'amadeus' ? ' • Amadeus' : ''}',
      isFeatured: hotel.source == 'local',
      hasDiscount: false,
      metadata: {
        'hotel': hotel,
        'source': hotel.source,
      },
    );
  }

  /// Create from Flight offer (will implement when flight models are available)
  factory ExploreItem.fromFlight(Map<String, dynamic> flightData) {
    return ExploreItem(
      id: flightData['id']?.toString() ?? '',
      type: ProductType.flights,
      name: '${flightData['origin']} → ${flightData['destination']}',
      price: flightData['price']?.toDouble(),
      currency: flightData['currency'] ?? 'USD',
      duration: flightData['duration'],
      subtitle: flightData['airline'] ?? 'Flight',
      isFeatured: false,
      hasDiscount: false,
      metadata: flightData,
    );
  }

  double get discountPercentage {
    if (!hasDiscount || originalPrice == null || price == null) return 0;
    return ((originalPrice! - price!) / originalPrice!) * 100;
  }

  String get priceDisplay {
    if (price == null) return 'Price on request';
    final currencySymbol = currency ?? '';
    final formattedPrice = price!.toStringAsFixed(0);
    return '$currencySymbol $formattedPrice';
  }

  String get originalPriceDisplay {
    if (originalPrice == null) return '';
    final currencySymbol = currency ?? '';
    return '$currencySymbol ${originalPrice!.toStringAsFixed(0)}';
  }
}

/// Explore filter options
class ExploreFilters {
  final ProductType? productType;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? provider; // 'local', 'amadeus', etc.
  final String? packageType; // 'umrah', 'hajj', etc.
  final bool? isFeatured;

  const ExploreFilters({
    this.productType,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.location,
    this.startDate,
    this.endDate,
    this.provider,
    this.packageType,
    this.isFeatured,
  });

  ExploreFilters copyWith({
    ProductType? productType,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? provider,
    String? packageType,
    bool? isFeatured,
  }) {
    return ExploreFilters(
      productType: productType ?? this.productType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      provider: provider ?? this.provider,
      packageType: packageType ?? this.packageType,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  bool get hasActiveFilters {
    return minPrice != null ||
        maxPrice != null ||
        minRating != null ||
        location != null ||
        startDate != null ||
        endDate != null ||
        provider != null ||
        packageType != null ||
        isFeatured != null;
  }

  void clearAll() {}
}
