/// Flight-related models for Amadeus API integration
library;

/// Airport model for autocomplete
class Airport {
  final String iataCode;
  final String name;
  final String? cityName;
  final String? cityCode;
  final String? countryCode;
  final String? countryName;

  Airport({
    required this.iataCode,
    required this.name,
    this.cityName,
    this.cityCode,
    this.countryCode,
    this.countryName,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      iataCode: json['iataCode'] as String,
      name: json['name'] as String,
      cityName: json['address']?['cityName'] as String?,
      cityCode: json['address']?['cityCode'] as String?,
      countryCode: json['address']?['countryCode'] as String?,
      countryName: json['address']?['countryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iataCode': iataCode,
      'name': name,
      'address': {
        if (cityName != null) 'cityName': cityName,
        if (cityCode != null) 'cityCode': cityCode,
        if (countryCode != null) 'countryCode': countryCode,
        if (countryName != null) 'countryName': countryName,
      }
    };
  }

  String get displayName => '$name ($iataCode)';
  String get fullDisplayName => cityName != null ? '$name, $cityName ($iataCode)' : displayName;
}

/// Price information
class Price {
  final String currency;
  final double total;
  final double base;
  final List<Tax> taxes;

  Price({
    required this.currency,
    required this.total,
    required this.base,
    required this.taxes,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      currency: json['currency'] as String,
      total: double.parse(json['total'].toString()),
      base: double.parse(json['base'].toString()),
      taxes: (json['taxes'] as List<dynamic>?)
              ?.map((e) => Tax.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'total': total.toString(),
      'base': base.toString(),
      'taxes': taxes.map((e) => e.toJson()).toList(),
    };
  }
}

/// Tax information
class Tax {
  final double amount;
  final String code;

  Tax({required this.amount, required this.code});

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      amount: double.parse(json['amount'].toString()),
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toString(),
      'code': code,
    };
  }
}

/// Flight segment (leg)
class FlightSegment {
  final String departure;
  final String arrival;
  final String departureTime;
  final String arrivalTime;
  final String carrierCode;
  final String flightNumber;
  final String? aircraft;
  final String duration;
  final int numberOfStops;

  FlightSegment({
    required this.departure,
    required this.arrival,
    required this.departureTime,
    required this.arrivalTime,
    required this.carrierCode,
    required this.flightNumber,
    this.aircraft,
    required this.duration,
    this.numberOfStops = 0,
  });

  factory FlightSegment.fromJson(Map<String, dynamic> json) {
    return FlightSegment(
      departure: (json['departure']?['iataCode'] as String?) ?? '',
      arrival: (json['arrival']?['iataCode'] as String?) ?? '',
      departureTime: (json['departure']?['at'] as String?) ?? '',
      arrivalTime: (json['arrival']?['at'] as String?) ?? '',
      carrierCode: (json['carrierCode'] as String?) ?? '',
      flightNumber: (json['number'] as String?) ?? '',
      aircraft: json['aircraft']?['code'] as String?,
      duration: (json['duration'] as String?) ?? 'PT0H0M',
      numberOfStops: json['numberOfStops'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departure': {'iataCode': departure, 'at': departureTime},
      'arrival': {'iataCode': arrival, 'at': arrivalTime},
      'carrierCode': carrierCode,
      'number': flightNumber,
      if (aircraft != null) 'aircraft': {'code': aircraft},
      'duration': duration,
      'numberOfStops': numberOfStops,
    };
  }

  String get route => '$departure → $arrival';
}

/// Itinerary (collection of segments)
class Itinerary {
  final String duration;
  final List<FlightSegment> segments;

  Itinerary({
    required this.duration,
    required this.segments,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      duration: (json['duration'] as String?) ?? 'PT0H0M',
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => FlightSegment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'segments': segments.map((e) => e.toJson()).toList(),
    };
  }

  int get totalStops => segments.fold(0, (sum, seg) => sum + seg.numberOfStops);
  String get stopsText => totalStops == 0 ? 'Non-stop' : '$totalStops Stop${totalStops > 1 ? 's' : ''}';
}

/// Flight offer from search
class FlightOffer {
  final String id;
  final String type;
  final String source;
  final bool instantTicketingRequired;
  final bool nonHomogeneous;
  final bool oneWay;
  final String lastTicketingDate;
  final int numberOfBookableSeats;
  final List<Itinerary> itineraries;
  final Price price;
  final String validatingAirlineCodes;
  final dynamic travelerPricings; // Can be List or Map
  final Map<String, dynamic> rawData;

  FlightOffer({
    required this.id,
    required this.type,
    required this.source,
    required this.instantTicketingRequired,
    required this.nonHomogeneous,
    required this.oneWay,
    required this.lastTicketingDate,
    required this.numberOfBookableSeats,
    required this.itineraries,
    required this.price,
    required this.validatingAirlineCodes,
    this.travelerPricings,
    required this.rawData,
  });

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    return FlightOffer(
      id: (json['id'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'flight-offer',
      source: (json['source'] as String?) ?? 'GDS',
      instantTicketingRequired: json['instantTicketingRequired'] as bool? ?? false,
      nonHomogeneous: json['nonHomogeneous'] as bool? ?? false,
      oneWay: json['oneWay'] as bool? ?? false,
      lastTicketingDate: json['lastTicketingDate'] as String? ?? '',
      numberOfBookableSeats: json['numberOfBookableSeats'] as int? ?? 0,
      itineraries: (json['itineraries'] as List<dynamic>?)
          ?.map((e) => Itinerary.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      price: json['price'] != null && json['price'] is Map<String, dynamic>
          ? Price.fromJson(json['price'] as Map<String, dynamic>)
          : Price(currency: 'USD', total: 0, base: 0, taxes: []),
      validatingAirlineCodes: json['validatingAirlineCodes'] is List
          ? ((json['validatingAirlineCodes'] as List).first as String?) ?? ''
          : (json['validatingAirlineCodes'] as String?) ?? '',
      travelerPricings: json['travelerPricings'], // Keep as dynamic
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() => rawData;

  String get mainCarrierCode => itineraries.first.segments.first.carrierCode;
  String get departureAirport => itineraries.first.segments.first.departure;
  String get arrivalAirport => itineraries.first.segments.last.arrival;
  String get route => '$departureAirport → $arrivalAirport';
  int get totalStops => itineraries.first.totalStops;
}

/// Traveler information for booking
class Traveler {
  final String id;
  final String dateOfBirth;
  final TravelerName name;
  final String gender;
  final TravelerContact contact;
  final List<TravelerDocument>? documents;

  Traveler({
    required this.id,
    required this.dateOfBirth,
    required this.name,
    required this.gender,
    required this.contact,
    this.documents,
  });

  factory Traveler.fromJson(Map<String, dynamic> json) {
    return Traveler(
      id: json['id'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      name: TravelerName.fromJson(json['name'] as Map<String, dynamic>),
      gender: json['gender'] as String,
      contact: TravelerContact.fromJson(json['contact'] as Map<String, dynamic>),
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => TravelerDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateOfBirth': dateOfBirth,
      'name': name.toJson(),
      'gender': gender,
      'contact': contact.toJson(),
      if (documents != null) 'documents': documents!.map((e) => e.toJson()).toList(),
    };
  }

  String get fullName => '${name.firstName} ${name.lastName}';
}

/// Traveler name
class TravelerName {
  final String firstName;
  final String lastName;

  TravelerName({
    required this.firstName,
    required this.lastName,
  });

  factory TravelerName.fromJson(Map<String, dynamic> json) {
    return TravelerName(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}

/// Traveler contact
class TravelerContact {
  final String emailAddress;
  final List<TravelerPhone> phones;

  TravelerContact({
    required this.emailAddress,
    required this.phones,
  });

  factory TravelerContact.fromJson(Map<String, dynamic> json) {
    return TravelerContact(
      emailAddress: json['emailAddress'] as String,
      phones: (json['phones'] as List<dynamic>)
          .map((e) => TravelerPhone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailAddress': emailAddress,
      'phones': phones.map((e) => e.toJson()).toList(),
    };
  }
}

/// Traveler phone
class TravelerPhone {
  final String deviceType;
  final String countryCallingCode;
  final String number;

  TravelerPhone({
    required this.deviceType,
    required this.countryCallingCode,
    required this.number,
  });

  factory TravelerPhone.fromJson(Map<String, dynamic> json) {
    return TravelerPhone(
      deviceType: json['deviceType'] as String,
      countryCallingCode: json['countryCallingCode'] as String,
      number: json['number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceType': deviceType,
      'countryCallingCode': countryCallingCode,
      'number': number,
    };
  }
}

/// Traveler document (passport)
class TravelerDocument {
  final String documentType;
  final String number;
  final String expiryDate;
  final String issuanceCountry;
  final String nationality;
  final bool holder;

  TravelerDocument({
    required this.documentType,
    required this.number,
    required this.expiryDate,
    required this.issuanceCountry,
    required this.nationality,
    required this.holder,
  });

  factory TravelerDocument.fromJson(Map<String, dynamic> json) {
    return TravelerDocument(
      documentType: json['documentType'] as String,
      number: json['number'] as String,
      expiryDate: json['expiryDate'] as String,
      issuanceCountry: json['issuanceCountry'] as String,
      nationality: json['nationality'] as String,
      holder: json['holder'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'number': number,
      'expiryDate': expiryDate,
      'issuanceCountry': issuanceCountry,
      'nationality': nationality,
      'holder': holder,
    };
  }
}

/// Flight booking model
class FlightBooking {
  final int id;
  final int? offerId;
  final int? flightId;
  final int customerId;
  final int? agentId;
  final String bookingReference;
  final String? confirmationCode;
  final String? pnr;
  final int passengers;
  final String flightClass;
  final double seatPrice;
  final double totalAmount;
  final double paidAmount;
  final double taxAmount;
  final double serviceFee;
  final double discountAmount;
  final String currency;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String passengerName;
  final String passengerEmail;
  final String? passengerPhone;
  final List<dynamic> passengerDetails;
  final String? specialRequests;
  final String? notes;
  final String? cancellationReason;
  final String source;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlightBooking({
    required this.id,
    this.offerId,
    this.flightId,
    required this.customerId,
    this.agentId,
    required this.bookingReference,
    this.confirmationCode,
    this.pnr,
    required this.passengers,
    required this.flightClass,
    required this.seatPrice,
    required this.totalAmount,
    required this.paidAmount,
    required this.taxAmount,
    required this.serviceFee,
    required this.discountAmount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.passengerName,
    required this.passengerEmail,
    this.passengerPhone,
    required this.passengerDetails,
    this.specialRequests,
    this.notes,
    this.cancellationReason,
    required this.source,
    this.confirmedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlightBooking.fromJson(Map<String, dynamic> json) {
    return FlightBooking(
      id: json['id'] as int,
      offerId: json['offer_id'] as int?,
      flightId: json['flight_id'] as int?,
      customerId: json['customer_id'] as int,
      agentId: json['agent_id'] as int?,
      bookingReference: json['booking_reference'] as String,
      confirmationCode: json['confirmation_code'] as String?,
      pnr: json['pnr'] as String?,
      passengers: json['passengers'] as int,
      flightClass: json['flight_class'] as String,
      seatPrice: double.parse(json['seat_price'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      paidAmount: double.parse(json['paid_amount'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      serviceFee: double.parse(json['service_fee'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      currency: json['currency'] as String,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      paymentMethod: json['payment_method'] as String?,
      passengerName: json['passenger_name'] as String,
      passengerEmail: json['passenger_email'] as String,
      passengerPhone: json['passenger_phone'] as String?,
      passengerDetails: json['passenger_details'] as List<dynamic>,
      specialRequests: json['special_requests'] as String?,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      source: json['source'] as String,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'flight_id': flightId,
      'customer_id': customerId,
      'agent_id': agentId,
      'booking_reference': bookingReference,
      'confirmation_code': confirmationCode,
      'pnr': pnr,
      'passengers': passengers,
      'flight_class': flightClass,
      'seat_price': seatPrice,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'tax_amount': taxAmount,
      'service_fee': serviceFee,
      'discount_amount': discountAmount,
      'currency': currency,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'passenger_name': passengerName,
      'passenger_email': passengerEmail,
      'passenger_phone': passengerPhone,
      'passenger_details': passengerDetails,
      'special_requests': specialRequests,
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'source': source,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  double get remainingBalance => totalAmount - paidAmount;
}
