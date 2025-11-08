class HotelSearchParams {
  final String cityCode;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int rooms;
  final int? minPrice;
  final int? maxPrice;
  final int? minRating;
  final String? source; // 'local', 'amadeus', or null for both

  HotelSearchParams({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.rooms,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.source,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      'city_code': cityCode,
      'check_in': checkIn.toIso8601String().split('T')[0],
      'check_out': checkOut.toIso8601String().split('T')[0],
      'adults': adults.toString(),
      'rooms': rooms.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (minRating != null) 'min_rating': minRating.toString(),
      if (source != null) 'source': source!,
    };
  }
}

class Hotel {
  final String id;
  final String name;
  final String? description;
  final String cityCode;
  final String? cityName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int rating;
  final double? guestRating;
  final int? reviewCount;
  final List<String> amenities;
  final String? imageUrl;
  final String source; // 'local' or 'amadeus'
  final double? distance;
  final String? distanceUnit;
  final List<HotelOffer>? offers;

  Hotel({
    required this.id,
    required this.name,
    this.description,
    required this.cityCode,
    this.cityName,
    this.address,
    this.latitude,
    this.longitude,
    required this.rating,
    this.guestRating,
    this.reviewCount,
    required this.amenities,
    this.imageUrl,
    required this.source,
    this.distance,
    this.distanceUnit,
    this.offers,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    // Parse offers from the offers field
    List<HotelOffer>? offers;
    if (json['offers'] != null) {
      offers = (json['offers'] as List)
          .map((o) => HotelOffer.fromJson(o as Map<String, dynamic>))
          .toList();
    }
    // If no offers but has top-level price field, create a default offer
    else if (json['price'] != null) {
      double priceAmount = 0.0;
      String priceCurrency = 'USD';
      
      if (json['price'] is Map) {
        final priceMap = json['price'] as Map<String, dynamic>;
        // Handle both numeric and string price values
        if (priceMap['amount'] != null) {
          if (priceMap['amount'] is num) {
            priceAmount = (priceMap['amount'] as num).toDouble();
          } else if (priceMap['amount'] is String) {
            priceAmount = double.tryParse(priceMap['amount'] as String) ?? 0.0;
          }
        }
        priceCurrency = priceMap['currency'] as String? ?? 'USD';
      } else if (json['price'] is num) {
        priceAmount = (json['price'] as num).toDouble();
      } else if (json['price'] is String) {
        priceAmount = double.tryParse(json['price'] as String) ?? 0.0;
      }
      
      offers = [
        HotelOffer(
          id: '${json['id']}_default',
          hotelId: json['id'].toString(),
          roomType: 'Standard Room',
          price: priceAmount,
          currency: priceCurrency,
          guests: 2,
          cancellable: false,
          breakfastIncluded: false,
        ),
      ];
    }
    
    return Hotel(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      cityCode: json['city_code'] as String? ?? json['cityCode'] as String? ?? json['city'] as String? ?? '',
      cityName: json['city_name'] as String? ?? json['cityName'] as String? ?? json['city'] as String?,
      address: json['address'] as String?,
      latitude: json['latitude'] != null 
          ? (json['latitude'] is num 
              ? (json['latitude'] as num).toDouble() 
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null 
          ? (json['longitude'] is num 
              ? (json['longitude'] as num).toDouble() 
              : double.tryParse(json['longitude'].toString()))
          : null,
      rating: json['rating'] as int? ?? json['star_rating'] as int? ?? 0,
      guestRating: json['guest_rating'] != null ? (json['guest_rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      amenities: json['amenities'] != null 
          ? List<String>.from(json['amenities'] as List)
          : [],
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      source: json['source'] as String? ?? 'local',
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      distanceUnit: json['distance_unit'] as String? ?? json['distanceUnit'] as String?,
      offers: offers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'city_code': cityCode,
      'city_name': cityName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'guest_rating': guestRating,
      'review_count': reviewCount,
      'amenities': amenities,
      'image_url': imageUrl,
      'source': source,
      'distance': distance,
      'distance_unit': distanceUnit,
      'offers': offers?.map((o) => o.toJson()).toList(),
    };
  }

  bool get isAmadeus => source == 'amadeus';
  bool get isLocal => source == 'local';

  String get displayLocation {
    if (address != null && address!.isNotEmpty) return address!;
    if (cityName != null && cityName!.isNotEmpty) return cityName!;
    return cityCode;
  }

  String get distanceText {
    if (distance == null) return '';
    return '${distance!.toStringAsFixed(1)} ${distanceUnit ?? 'km'} from center';
  }

  double? get lowestPrice {
    if (offers == null || offers!.isEmpty) return null;
    return offers!.map((o) => o.price).reduce((a, b) => a < b ? a : b);
  }
}

class HotelOffer {
  final String id;
  final String hotelId;
  final String roomType;
  final String? bedType;
  final String? description;
  final double price;
  final String currency;
  final int guests;
  final bool cancellable;
  final String? cancellationDeadline;
  final bool breakfastIncluded;
  final List<String>? roomAmenities;

  HotelOffer({
    required this.id,
    required this.hotelId,
    required this.roomType,
    this.bedType,
    this.description,
    required this.price,
    required this.currency,
    required this.guests,
    required this.cancellable,
    this.cancellationDeadline,
    required this.breakfastIncluded,
    this.roomAmenities,
  });

  factory HotelOffer.fromJson(Map<String, dynamic> json) {
    // Handle both flat price (num) and nested price object {amount, currency}
    double priceValue = 0.0;
    String currencyValue = 'USD';
    
    if (json['price'] != null) {
      if (json['price'] is Map) {
        final priceMap = json['price'] as Map<String, dynamic>;
        priceValue = priceMap['amount'] != null ? (priceMap['amount'] as num).toDouble() : 0.0;
        currencyValue = priceMap['currency'] as String? ?? 'USD';
      } else if (json['price'] is num) {
        priceValue = (json['price'] as num).toDouble();
        currencyValue = json['currency'] as String? ?? 'USD';
      }
    }
    
    // Safe parsing of guests field - only cast if it's an int
    int guestsValue = 1;
    if (json['guests'] != null && json['guests'] is int) {
      guestsValue = json['guests'] as int;
    } else if (json['adults'] != null && json['adults'] is int) {
      guestsValue = json['adults'] as int;
    }
    
    return HotelOffer(
      id: json['id']?.toString() ?? 'unknown',
      hotelId: json['hotel_id']?.toString() ?? json['hotelId']?.toString() ?? 'unknown',
      roomType: json['room_type'] as String? ?? json['roomType'] as String? ?? 'Standard Room',
      bedType: json['bed_type'] as String? ?? json['bedType'] as String?,
      description: json['description'] as String?,
      price: priceValue,
      currency: currencyValue,
      guests: guestsValue,
      cancellable: json['cancellable'] as bool? ?? json['is_cancellable'] as bool? ?? false,
      cancellationDeadline: json['cancellation_deadline'] as String? ?? json['cancellationDeadline'] as String?,
      breakfastIncluded: json['breakfast_included'] as bool? ?? json['breakfastIncluded'] as bool? ?? false,
      roomAmenities: json['room_amenities'] != null
          ? List<String>.from(json['room_amenities'] as List)
          : json['roomAmenities'] != null
              ? List<String>.from(json['roomAmenities'] as List)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'room_type': roomType,
      'bed_type': bedType,
      'description': description,
      'price': price,
      'currency': currency,
      'guests': guests,
      'cancellable': cancellable,
      'cancellation_deadline': cancellationDeadline,
      'breakfast_included': breakfastIncluded,
      'room_amenities': roomAmenities,
    };
  }

  String get priceText => '$currency ${price.toStringAsFixed(2)}';
}

class HotelBooking {
  final String? id;
  final String hotelId;
  final String offerId;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<BookingGuest> guests;
  final String? specialRequests;
  final double totalPrice;
  final String currency;
  final String? status;
  final String? confirmationNumber;

  HotelBooking({
    this.id,
    required this.hotelId,
    required this.offerId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.specialRequests,
    required this.totalPrice,
    required this.currency,
    this.status,
    this.confirmationNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'hotel_id': hotelId,
      'offer_id': offerId,
      'check_in': checkIn.toIso8601String().split('T')[0],
      'check_out': checkOut.toIso8601String().split('T')[0],
      'guests': guests.map((g) => g.toJson()).toList(),
      'special_requests': specialRequests,
      'total_price': totalPrice,
      'currency': currency,
      if (status != null) 'status': status,
      if (confirmationNumber != null) 'confirmation_number': confirmationNumber,
    };
  }

  factory HotelBooking.fromJson(Map<String, dynamic> json) {
    return HotelBooking(
      id: json['id']?.toString(),
      hotelId: json['hotel_id'].toString(),
      offerId: json['offer_id'].toString(),
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
      guests: (json['guests'] as List).map((g) => BookingGuest.fromJson(g as Map<String, dynamic>)).toList(),
      specialRequests: json['special_requests'] as String?,
      totalPrice: (json['total_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String?,
      confirmationNumber: json['confirmation_number'] as String?,
    );
  }
}

class BookingGuest {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  BookingGuest({
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  factory BookingGuest.fromJson(Map<String, dynamic> json) {
    return BookingGuest(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}
