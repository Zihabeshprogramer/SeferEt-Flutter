import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

@JsonSerializable()
class Package {
  final int id;
  final String slug;
  final String name;
  final String description;
  final String type;
  @JsonKey(name: 'type_label')
  final String typeLabel;
  final int duration;
  @JsonKey(name: 'duration_formatted')
  final String durationFormatted;
  @JsonKey(name: 'base_price')
  final double basePrice;
  @JsonKey(name: 'total_price')
  final double? totalPrice;
  final String currency;
  final List<String> destinations;
  final List<String> features;
  final List<String> highlights;
  final List<PackageImage> images;
  final PackageRating rating;
  @JsonKey(name: 'bookings_count')
  final int bookingsCount;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'is_premium')
  final bool isPremium;
  @JsonKey(name: 'instant_booking')
  final bool instantBooking;
  @JsonKey(name: 'free_cancellation')
  final bool freeCancellation;
  final PackageCreator? creator;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  final PackageAvailability availability;
  
  // Detailed fields (only available in detailed API response)
  @JsonKey(name: 'detailed_description')
  final String? detailedDescription;
  final List<String>? inclusions;
  final List<String>? exclusions;
  final List<PackageActivity>? activities;
  final List<PackageHotel>? hotels;
  final List<PackageFlight>? flights;
  final List<PackageTransport>? transport;
  final PackagePricing? pricing;
  final PackagePolicies? policies;

  Package({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.type,
    required this.typeLabel,
    required this.duration,
    required this.durationFormatted,
    required this.basePrice,
    this.totalPrice,
    required this.currency,
    required this.destinations,
    required this.features,
    required this.highlights,
    required this.images,
    required this.rating,
    required this.bookingsCount,
    required this.isFeatured,
    required this.isPremium,
    required this.instantBooking,
    required this.freeCancellation,
    this.creator,
    this.createdAt,
    required this.availability,
    this.detailedDescription,
    this.inclusions,
    this.exclusions,
    this.activities,
    this.hotels,
    this.flights,
    this.transport,
    this.pricing,
    this.policies,
  });

  factory Package.fromJson(Map<String, dynamic> json) => _$PackageFromJson(json);
  Map<String, dynamic> toJson() => _$PackageToJson(this);

  String get mainImageUrl {
    if (images.isNotEmpty) {
      final mainImage = images.firstWhere(
        (img) => img.isMain,
        orElse: () => images.first,
      );
      return mainImage.urls['medium'] ?? mainImage.urls['original'] ?? '';
    }
    return '';
  }

  double get displayPrice => totalPrice ?? basePrice;
  
  bool get hasDiscount => totalPrice != null && totalPrice! < basePrice;
  
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((basePrice - totalPrice!) / basePrice * 100);
  }
}

@JsonSerializable()
class PackageImage {
  final String? id;
  final String? filename;
  @JsonKey(name: 'original_name')
  final String? originalName;
  @JsonKey(name: 'alt_text')
  final String altText;
  @JsonKey(name: 'is_main')
  final bool isMain;
  final Map<String, String> urls;

  PackageImage({
    this.id,
    this.filename,
    this.originalName,
    required this.altText,
    required this.isMain,
    required this.urls,
  });

  factory PackageImage.fromJson(Map<String, dynamic> json) => _$PackageImageFromJson(json);
  Map<String, dynamic> toJson() => _$PackageImageToJson(this);
}

@JsonSerializable()
class PackageRating {
  final double average;
  final int count;

  PackageRating({
    required this.average,
    required this.count,
  });

  factory PackageRating.fromJson(Map<String, dynamic> json) => _$PackageRatingFromJson(json);
  Map<String, dynamic> toJson() => _$PackageRatingToJson(this);
}

@JsonSerializable()
class PackageCreator {
  final int id;
  final String name;

  PackageCreator({
    required this.id,
    required this.name,
  });

  factory PackageCreator.fromJson(Map<String, dynamic> json) => _$PackageCreatorFromJson(json);
  Map<String, dynamic> toJson() => _$PackageCreatorToJson(this);
}

@JsonSerializable()
class PackageAvailability {
  @JsonKey(name: 'available_from')
  final String? availableFrom;
  @JsonKey(name: 'available_until')
  final String? availableUntil;
  @JsonKey(name: 'min_participants')
  final int? minParticipants;
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  @JsonKey(name: 'current_bookings')
  final int currentBookings;
  @JsonKey(name: 'availability_percentage')
  final int availabilityPercentage;

  PackageAvailability({
    this.availableFrom,
    this.availableUntil,
    this.minParticipants,
    this.maxParticipants,
    required this.currentBookings,
    required this.availabilityPercentage,
  });

  factory PackageAvailability.fromJson(Map<String, dynamic> json) => _$PackageAvailabilityFromJson(json);
  Map<String, dynamic> toJson() => _$PackageAvailabilityToJson(this);
}

@JsonSerializable()
class PackageActivity {
  final int id;
  @JsonKey(name: 'day_number')
  final int dayNumber;
  @JsonKey(name: 'activity_name')
  final String activityName;
  final String description;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'end_time')
  final String? endTime;
  final String? location;
  final String category;
  @JsonKey(name: 'is_included')
  final bool isIncluded;
  @JsonKey(name: 'additional_cost')
  final double? additionalCost;
  @JsonKey(name: 'is_optional')
  final bool isOptional;

  PackageActivity({
    required this.id,
    required this.dayNumber,
    required this.activityName,
    required this.description,
    this.startTime,
    this.endTime,
    this.location,
    required this.category,
    required this.isIncluded,
    this.additionalCost,
    required this.isOptional,
  });

  factory PackageActivity.fromJson(Map<String, dynamic> json) => _$PackageActivityFromJson(json);
  Map<String, dynamic> toJson() => _$PackageActivityToJson(this);
}

@JsonSerializable()
class PackageHotel {
  final int id;
  final String name;
  final double? rating;
  final String? location;
  final String? description;
  final PackageHotelPivot pivot;

  PackageHotel({
    required this.id,
    required this.name,
    this.rating,
    this.location,
    this.description,
    required this.pivot,
  });

  factory PackageHotel.fromJson(Map<String, dynamic> json) => _$PackageHotelFromJson(json);
  Map<String, dynamic> toJson() => _$PackageHotelToJson(this);
}

@JsonSerializable()
class PackageHotelPivot {
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  final int nights;
  @JsonKey(name: 'room_type')
  final String roomType;
  @JsonKey(name: 'rooms_needed')
  final int roomsNeeded;

  PackageHotelPivot({
    required this.isPrimary,
    required this.nights,
    required this.roomType,
    required this.roomsNeeded,
  });

  factory PackageHotelPivot.fromJson(Map<String, dynamic> json) => _$PackageHotelPivotFromJson(json);
  Map<String, dynamic> toJson() => _$PackageHotelPivotToJson(this);
}

@JsonSerializable()
class PackageFlight {
  final int id;
  final String airline;
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  @JsonKey(name: 'departure_airport')
  final String departureAirport;
  @JsonKey(name: 'arrival_airport')
  final String arrivalAirport;
  @JsonKey(name: 'departure_time')
  final String? departureTime;
  @JsonKey(name: 'arrival_time')
  final String? arrivalTime;
  final PackageFlightPivot pivot;

  PackageFlight({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    this.departureTime,
    this.arrivalTime,
    required this.pivot,
  });

  factory PackageFlight.fromJson(Map<String, dynamic> json) => _$PackageFlightFromJson(json);
  Map<String, dynamic> toJson() => _$PackageFlightToJson(this);
}

@JsonSerializable()
class PackageFlightPivot {
  @JsonKey(name: 'flight_type')
  final String flightType;
  @JsonKey(name: 'seats_allocated')
  final int seatsAllocated;

  PackageFlightPivot({
    required this.flightType,
    required this.seatsAllocated,
  });

  factory PackageFlightPivot.fromJson(Map<String, dynamic> json) => _$PackageFlightPivotFromJson(json);
  Map<String, dynamic> toJson() => _$PackageFlightPivotToJson(this);
}

@JsonSerializable()
class PackageTransport {
  final int id;
  @JsonKey(name: 'company_name')
  final String companyName;
  @JsonKey(name: 'vehicle_type')
  final String vehicleType;
  final int capacity;
  final PackageTransportPivot pivot;

  PackageTransport({
    required this.id,
    required this.companyName,
    required this.vehicleType,
    required this.capacity,
    required this.pivot,
  });

  factory PackageTransport.fromJson(Map<String, dynamic> json) => _$PackageTransportFromJson(json);
  Map<String, dynamic> toJson() => _$PackageTransportToJson(this);
}

@JsonSerializable()
class PackageTransportPivot {
  @JsonKey(name: 'pickup_location')
  final String pickupLocation;
  @JsonKey(name: 'dropoff_location')
  final String dropoffLocation;
  @JsonKey(name: 'day_of_itinerary')
  final int dayOfItinerary;

  PackageTransportPivot({
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.dayOfItinerary,
  });

  factory PackageTransportPivot.fromJson(Map<String, dynamic> json) => _$PackageTransportPivotFromJson(json);
  Map<String, dynamic> toJson() => _$PackageTransportPivotToJson(this);
}

@JsonSerializable()
class PackagePricing {
  @JsonKey(name: 'base_price')
  final double basePrice;
  @JsonKey(name: 'child_price')
  final double? childPrice;
  @JsonKey(name: 'infant_price')
  final double? infantPrice;
  @JsonKey(name: 'single_supplement')
  final double? singleSupplement;
  @JsonKey(name: 'total_price')
  final double? totalPrice;
  @JsonKey(name: 'pricing_breakdown')
  final List<PricingBreakdownItem> pricingBreakdown;
  @JsonKey(name: 'optional_addons')
  final List<OptionalAddon> optionalAddons;
  @JsonKey(name: 'payment_terms')
  final Map<String, dynamic> paymentTerms;
  @JsonKey(name: 'cancellation_policy')
  final Map<String, dynamic> cancellationPolicy;
  @JsonKey(name: 'deposit_percentage')
  final double? depositPercentage;
  final String currency;

  PackagePricing({
    required this.basePrice,
    this.childPrice,
    this.infantPrice,
    this.singleSupplement,
    this.totalPrice,
    required this.pricingBreakdown,
    required this.optionalAddons,
    required this.paymentTerms,
    required this.cancellationPolicy,
    this.depositPercentage,
    required this.currency,
  });

  factory PackagePricing.fromJson(Map<String, dynamic> json) => _$PackagePricingFromJson(json);
  Map<String, dynamic> toJson() => _$PackagePricingToJson(this);
}

@JsonSerializable()
class PricingBreakdownItem {
  final String item;
  final double amount;

  PricingBreakdownItem({
    required this.item,
    required this.amount,
  });

  factory PricingBreakdownItem.fromJson(Map<String, dynamic> json) => _$PricingBreakdownItemFromJson(json);
  Map<String, dynamic> toJson() => _$PricingBreakdownItemToJson(this);
}

@JsonSerializable()
class OptionalAddon {
  final String name;
  final double price;
  final String? description;

  OptionalAddon({
    required this.name,
    required this.price,
    this.description,
  });

  factory OptionalAddon.fromJson(Map<String, dynamic> json) => _$OptionalAddonFromJson(json);
  Map<String, dynamic> toJson() => _$OptionalAddonToJson(this);
}

@JsonSerializable()
class PackagePolicies {
  @JsonKey(name: 'required_documents')
  final List<String> requiredDocuments;
  @JsonKey(name: 'visa_requirements')
  final List<String> visaRequirements;
  @JsonKey(name: 'health_requirements')
  final List<String> healthRequirements;
  @JsonKey(name: 'age_restrictions')
  final Map<String, dynamic> ageRestrictions;
  @JsonKey(name: 'terms_accepted')
  final Map<String, dynamic> termsAccepted;

  PackagePolicies({
    required this.requiredDocuments,
    required this.visaRequirements,
    required this.healthRequirements,
    required this.ageRestrictions,
    required this.termsAccepted,
  });

  factory PackagePolicies.fromJson(Map<String, dynamic> json) => _$PackagePoliciesFromJson(json);
  Map<String, dynamic> toJson() => _$PackagePoliciesToJson(this);
}

@JsonSerializable()
class PackageListResponse {
  final List<Package> packages;
  final Pagination pagination;

  PackageListResponse({
    required this.packages,
    required this.pagination,
  });

  factory PackageListResponse.fromJson(Map<String, dynamic> json) => _$PackageListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PackageListResponseToJson(this);
}

@JsonSerializable()
class Pagination {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;
  @JsonKey(name: 'has_more_pages')
  final bool hasMorePages;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMorePages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}

@JsonSerializable()
class PackageSearchResponse {
  final List<Package> packages;
  final Pagination pagination;
  final String query;

  PackageSearchResponse({
    required this.packages,
    required this.pagination,
    required this.query,
  });

  factory PackageSearchResponse.fromJson(Map<String, dynamic> json) => _$PackageSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PackageSearchResponseToJson(this);
}

@JsonSerializable()
class PackageCategories {
  final List<PackageType> types;
  final List<Destination> destinations;
  @JsonKey(name: 'price_ranges')
  final List<PriceRange> priceRanges;
  final List<Duration> durations;

  PackageCategories({
    required this.types,
    required this.destinations,
    required this.priceRanges,
    required this.durations,
  });

  factory PackageCategories.fromJson(Map<String, dynamic> json) => _$PackageCategoriesFromJson(json);
  Map<String, dynamic> toJson() => _$PackageCategoriesToJson(this);
}

@JsonSerializable()
class PackageType {
  final String key;
  final String label;
  final int count;

  PackageType({
    required this.key,
    required this.label,
    required this.count,
  });

  factory PackageType.fromJson(Map<String, dynamic> json) => _$PackageTypeFromJson(json);
  Map<String, dynamic> toJson() => _$PackageTypeToJson(this);
}

@JsonSerializable()
class Destination {
  final String name;
  final int count;

  Destination({
    required this.name,
    required this.count,
  });

  factory Destination.fromJson(Map<String, dynamic> json) => _$DestinationFromJson(json);
  Map<String, dynamic> toJson() => _$DestinationToJson(this);
}

@JsonSerializable()
class PriceRange {
  final double min;
  final double? max;
  final String label;
  final int count;

  PriceRange({
    required this.min,
    this.max,
    required this.label,
    required this.count,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) => _$PriceRangeFromJson(json);
  Map<String, dynamic> toJson() => _$PriceRangeToJson(this);
}

@JsonSerializable()
class Duration {
  final int duration;
  final String label;
  final int count;

  Duration({
    required this.duration,
    required this.label,
    required this.count,
  });

  factory Duration.fromJson(Map<String, dynamic> json) => _$DurationFromJson(json);
  Map<String, dynamic> toJson() => _$DurationToJson(this);
}