import 'dart:convert';
import 'package:dio/dio.dart';

/// Service for interacting with Amadeus flight search and booking endpoints
class AmadeusFlightService {
  final Dio _dio;
  final String baseUrl;

  AmadeusFlightService({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 45);
    _dio.options.receiveTimeout = const Duration(minutes: 2);
    _dio.options.maxRedirects = 5;
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🛫 Flight API Request: ${options.method} ${options.path}');
          print('Query Parameters: ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          try {
            final responseSize = response.data.toString().length;
            print('✅ Flight API Response: ${response.statusCode}');
            print('Response size: $responseSize characters');
            
            // Check if response is too large (> 5MB)
            if (responseSize > 5000000) {
              print('⚠️ Warning: Response is very large ($responseSize characters)');
            }
          } catch (e) {
            print('⚠️ Error getting response size: $e');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Flight API Error: ${error.message}');
          if (error.response != null) {
            print('Status: ${error.response?.statusCode}');
            print('Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Search for flight offers
  /// 
  /// Parameters:
  /// - [origin]: IATA airport code (e.g., 'JFK')
  /// - [destination]: IATA airport code (e.g., 'LAX')
  /// - [departureDate]: Departure date in 'YYYY-MM-DD' format
  /// - [returnDate]: Optional return date in 'YYYY-MM-DD' format
  /// - [adults]: Number of adult passengers (default: 1)
  /// - [token]: Authentication token
  Future<Map<String, dynamic>> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    int adults = 1,
    required String token,
  }) async {
    try {
      final queryParams = {
        'origin': origin.toUpperCase(),
        'destination': destination.toUpperCase(),
        'departure_date': departureDate,
        'adults': adults,
      };

      if (returnDate != null && returnDate.isNotEmpty) {
        queryParams['return_date'] = returnDate;
      }

      final response = await _dio.get(
        '/api/flights/search',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true, // Accept all status codes
          responseType: ResponseType.plain, // Get as plain text first
        ),
      );

      if (response.statusCode == 200) {
        // Try to parse the response manually to catch JSON errors
        try {
          final responseText = response.data as String;
          print('Raw response length: ${responseText.length} characters');
          
          // Try to parse JSON
          final jsonData = _parseJson(responseText);
          return jsonData;
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          if (e is FormatException) {
            // Log the area around the error
            final errorOffset = _extractOffset(e.toString());
            if (errorOffset != null && response.data is String) {
              final text = response.data as String;
              final start = errorOffset > 100 ? errorOffset - 100 : 0;
              final end = errorOffset + 100 < text.length ? errorOffset + 100 : text.length;
              print('Context around error (offset $errorOffset):');
              print('...${text.substring(start, end)}...');
            }
            
            // If JSON repair failed, return a user-friendly error
            if (e.toString().contains('Unexpected end of input')) {
              return {
                'success': false,
                'message': 'Server response was incomplete. The server may be overloaded. Please try again.',
                'data': null,
              };
            }
          }
          
          // Return generic parsing error
          return {
            'success': false,
            'message': 'Unable to process server response. Please try again later.',
            'data': null,
          };
        }
      } else if (response.statusCode == 500) {
        print('❌ Server Error 500 - Backend is experiencing issues');
        return {
          'success': false,
          'message': 'Server error. The backend is having issues processing this request.',
          'data': null,
        };
      } else {
        print('❌ HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Request failed with status ${response.statusCode}',
          'data': null,
        };
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Search for cheapest prices across multiple dates (batch request)
  /// 
  /// Parameters:
  /// - [origin]: IATA airport code (e.g., 'JFK')
  /// - [destination]: IATA airport code (e.g., 'LAX')
  /// - [departureDates]: List of departure dates in 'YYYY-MM-DD' format
  /// - [returnDate]: Optional return date in 'YYYY-MM-DD' format
  /// - [adults]: Number of adult passengers (default: 1)
  /// - [token]: Authentication token
  /// 
  /// Returns a map of date -> cheapest price
  Future<Map<String, Map<String, dynamic>>> searchFlightsBatch({
    required String origin,
    required String destination,
    required List<String> departureDates,
    String? returnDate,
    int adults = 1,
    required String token,
  }) async {
    try {
      final queryParams = {
        'origin': origin.toUpperCase(),
        'destination': destination.toUpperCase(),
        'departure_dates': departureDates.join(','), // Send as comma-separated
        'adults': adults,
      };

      if (returnDate != null && returnDate.isNotEmpty) {
        queryParams['return_date'] = returnDate;
      }

      final response = await _dio.get(
        '/api/flights/search-batch',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final responseText = response.data as String;
          print('Batch response length: ${responseText.length} characters');
          
          final jsonData = _parseJson(responseText);
          
          print('📦 Batch JSON parsed successfully');
          print('Batch success: ${jsonData['success']}');
          print('Batch data type: ${jsonData['data']?.runtimeType}');
          
          // Expected format: {"success": true, "data": {"2025-10-31": {...}, "2025-11-01": {...}}}
          if (jsonData['success'] == true && jsonData['data'] != null) {
            final dataMap = jsonData['data'] as Map;
            print('📊 Batch data contains ${dataMap.length} dates: ${dataMap.keys.toList()}');
            
            return Map<String, Map<String, dynamic>>.from(
              dataMap.map(
                (key, value) => MapEntry(key as String, value as Map<String, dynamic>),
              ),
            );
          } else {
            print('⚠️ Batch request returned success=false or no data');
            print('Message: ${jsonData['message']}');
          }
          return {};
        } catch (e, stackTrace) {
          print('❌ Batch JSON Parse Error: $e');
          print('Stack: $stackTrace');
          return {};
        }
      } else {
        print('❌ Batch HTTP Error ${response.statusCode}');
        if (response.data != null) {
          print('Response: ${response.data.toString().substring(0, response.data.toString().length > 500 ? 500 : response.data.toString().length)}');
        }
        return {};
      }
    } catch (e, stackTrace) {
      print('❌ Batch search error: $e');
      print('Stack: $stackTrace');
      return {};
    }
  }

  /// Book a flight
  /// 
  /// Parameters:
  /// - [offer]: The selected flight offer from search results
  /// - [travelers]: List of traveler information
  /// - [customerId]: ID of the customer making the booking (null for guests)
  /// - [guestEmail]: Email for guest bookings
  /// - [guestName]: Name for guest bookings
  /// - [agentId]: Optional ID of the agent processing the booking
  /// - [specialRequests]: Optional special requests
  /// - [token]: Authentication token
  Future<Map<String, dynamic>> bookFlight({
    required Map<String, dynamic> offer,
    required List<Map<String, dynamic>> travelers,
    int? customerId,
    String? guestEmail,
    String? guestName,
    int? agentId,
    String? specialRequests,
    required String token,
  }) async {
    try {
      final payload = {
        'offer': offer,
        'travelers': travelers,
        if (customerId != null) 'customer_id': customerId,
        if (guestEmail != null) 'guest_email': guestEmail,
        if (guestName != null) 'guest_name': guestName,
        if (agentId != null) 'agent_id': agentId,
        if (specialRequests != null && specialRequests.isNotEmpty)
          'special_requests': specialRequests,
      };

      final response = await _dio.post(
        '/api/flights/book',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to book flight',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get booking by PNR
  /// 
  /// Parameters:
  /// - [pnr]: Passenger Name Record
  /// - [token]: Authentication token
  Future<Map<String, dynamic>> getBookingByPnr({
    required String pnr,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/flights/booking/$pnr',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to retrieve booking',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Search airports by keyword for autocomplete
  /// 
  /// Parameters:
  /// - [keyword]: Search keyword (city or airport name)
  /// - [token]: Authentication token (optional for this public endpoint)
  Future<List<Map<String, dynamic>>> searchAirports({
    required String keyword,
    required String token,
  }) async {
    try {
      // Build headers - only add auth if token is not empty
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get(
        '/api/flights/airports',
        queryParameters: {
          'keyword': keyword,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return (data['data'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to search airports',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get all bookings for the authenticated user
  /// 
  /// Parameters:
  /// - [token]: Authentication token
  Future<List<Map<String, dynamic>>> getMyBookings({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/flights/bookings',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return (data['data'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to retrieve bookings',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get detailed offer information by ID
  /// 
  /// Parameters:
  /// - [offerId]: Offer ID from search results
  /// - [token]: Authentication token
  Future<Map<String, dynamic>> getOfferDetails({
    required String offerId,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/flights/offer/$offerId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to retrieve offer details',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Validate and reconfirm pricing before booking
  /// 
  /// Parameters:
  /// - [offer]: The flight offer to validate
  /// - [token]: Authentication token
  Future<Map<String, dynamic>> validateOfferPricing({
    required Map<String, dynamic> offer,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/api/flights/validate-pricing',
        data: {'offer': offer},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to validate pricing',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Cancel a booking
  /// 
  /// Parameters:
  /// - [bookingId]: Booking ID to cancel
  /// - [reason]: Cancellation reason
  /// - [token]: Authentication token
  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    String? reason,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/api/flights/booking/$bookingId/cancel',
        data: {
          if (reason != null) 'reason': reason,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to cancel booking',
        );
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Parse JSON with better error handling
  Map<String, dynamic> _parseJson(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded as Map<String, dynamic>;
    } on FormatException catch (e) {
      print('FormatException in JSON parsing: $e');
      
      // Check if it's a truncated response
      if (e.toString().contains('Unexpected end of input')) {
        print('Response appears to be truncated at ${text.length} characters');
        // Try to salvage what we can by closing the JSON
        final repaired = _repairTruncatedJson(text);
        if (repaired != text) {
          try {
            final decoded = jsonDecode(repaired);
            return decoded as Map<String, dynamic>;
          } catch (e) {
            print('Could not repair truncated JSON: $e');
          }
        }
      }
      
      // Check if it's an unexpected character error
      if (e.toString().contains('Unexpected character')) {
        print('Unexpected character detected - attempting to fix structure');
        // Log context around error
        final offset = _extractOffset(e.toString());
        if (offset != null && offset < text.length) {
          final start = offset > 100 ? offset - 100 : 0;
          final end = offset + 100 < text.length ? offset + 100 : text.length;
          print('Context: ...${text.substring(start, end)}...');
        }
      }
      
      // Try to clean the JSON
      final cleaned = _cleanJson(text);
      if (cleaned != text) {
        print('Attempting to parse cleaned JSON...');
        try {
          final decoded = jsonDecode(cleaned);
          return decoded as Map<String, dynamic>;
        } catch (cleanError) {
          print('Cleaned JSON also failed: $cleanError');
        }
      }
      
      // If all parsing attempts failed, return error
      print('All JSON parsing attempts failed');
      throw FormatException('Invalid JSON structure from server');
    } catch (e) {
      // Catch any other JSON errors
      print('JSON parsing error: $e');
      throw FormatException('Invalid JSON from server: $e');
    }
  }

  /// Attempt to repair truncated JSON by closing brackets
  String _repairTruncatedJson(String text) {
    String repaired = text.trim();
    
    print('🔧 Attempting to repair truncated JSON (${repaired.length} chars)');
    print('Last 100 chars: ...${repaired.substring(repaired.length > 100 ? repaired.length - 100 : 0)}');
    
    // Count open and close brackets
    int openBraces = '{'.allMatches(repaired).length;
    int closeBraces = '}'.allMatches(repaired).length;
    int openBrackets = '['.allMatches(repaired).length;
    int closeBrackets = ']'.allMatches(repaired).length;
    
    print('Brackets: { $openBraces/$closeBraces } [ $openBrackets/$closeBrackets ]');
    
    // If truncated in the middle of a property name or value
    if (repaired.endsWith('"')) {
      // Already ends with quote, just close brackets
    } else if (!repaired.endsWith('}') && !repaired.endsWith(']') && !repaired.endsWith(',')) {
      // Truncated mid-value, try to close the value
      final lastQuote = repaired.lastIndexOf('"');
      final lastColon = repaired.lastIndexOf(':');
      final lastComma = repaired.lastIndexOf(',');
      
      if (lastColon > lastQuote && lastColon > lastComma) {
        // We're in a value after colon, close it with quote
        print('Adding closing quote for truncated value');
        repaired += '"';
      } else if (lastComma > lastQuote) {
        // Truncated after comma but before property name - remove the trailing comma
        print('Removing trailing comma');
        repaired = repaired.substring(0, repaired.length - 1).trimRight();
      }
    }
    
    // Close any unclosed brackets in reverse order (LIFO)
    final needed = (openBrackets - closeBrackets) + (openBraces - closeBraces);
    if (needed > 0) {
      print('Closing $needed unclosed brackets/braces');
      // Close brackets/braces
      for (int i = 0; i < openBrackets - closeBrackets; i++) {
        repaired += ']';
      }
      for (int i = 0; i < openBraces - closeBraces; i++) {
        repaired += '}';
      }
    }
    
    print('✅ Repaired JSON (${repaired.length} chars)');
    return repaired;
  }
  
  /// Attempt to clean malformed JSON
  String _cleanJson(String text) {
    // Remove null bytes
    String cleaned = text.replaceAll(RegExp(r'\x00'), '');
    // Remove invalid control characters (except newline, tab, carriage return)
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
    
    // Fix backend typo: "fale" should be "false"
    cleaned = cleaned.replaceAll(':fale', ':false');
    cleaned = cleaned.replaceAll(':Fale', ':false');
    
    // Fix missing opening quote before property names after comma
    // Pattern: ,propertyName" should be ,"propertyName"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r',([a-zA-Z_]\w*)":'),
      (match) => ',"${match.group(1)}":',
    );
    
    // Fix missing opening quote after opening brace
    // Pattern: {propertyName": should be {"propertyName":
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\{([a-zA-Z_]\w*)":'),
      (match) => '{"${match.group(1)}":',
    );
    
    // Fix missing opening quote before array property (with colon and bracket)
    // Pattern: propertyName:[ should be "propertyName":[
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([,{])([a-zA-Z_]\w*):(\[)'),
      (match) => '${match.group(1)}"${match.group(2)}":${match.group(3)}',
    );
    
    // Fix property names that are completely unquoted (no quotes at all)
    // Pattern: {code:"value" or ,code:"value" should be {"code":"value" or ,"code":"value"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([,{])([a-zA-Z_]\w+):'),
      (match) {
        final prefix = match.group(1)!;
        final propName = match.group(2)!;
        // Only add quotes if property name isn't already quoted
        if (!cleaned.substring(match.start - 1 > 0 ? match.start - 1 : 0, match.start).contains('"')) {
          return '$prefix"$propName":';
        }
        return match.group(0)!;
      },
    );
    
    // Fix missing comma between closing quote and next property
    // Pattern: "value""property": should be "value","property":
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'""([a-zA-Z_]\w*)":'),
      (match) => '","${match.group(1)}":',
    );
    
    // Fix missing comma between closing brace/bracket and opening quote
    // Pattern: }"property or ]"property should be },"property or ],"property
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([}\]])"([a-zA-Z_]\w*)":'),
      (match) => '${match.group(1)},"${match.group(2)}":',
    );
    
    // Fix double commas
    cleaned = cleaned.replaceAll(',,', ',');
    
    // Fix missing quotes after duration strings (ISO 8601 duration)
    // Pattern: "property":} or "property":, should be "property":null} or "property":null,
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'"(\w+)":(\s*[},])'),
      (match) => '"${match.group(1)}":null${match.group(2)}',
    );
    
    // Fix missing quotes after duration strings (ISO 8601 duration)
    // Pattern: "duration":"PT10H9M, should be "duration":"PT10H9M",
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'"duration":"(PT[\dHMS]+),'),
      (match) => '"duration":"${match.group(1)}",',
    );
    
    // Fix missing quotes after ISO datetime strings
    // Pattern: "at":"2025-11-21T05:35:00} should be "at":"2025-11-21T05:35:00"}
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'"at":"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})([},])'),
      (match) => '"at":"${match.group(1)}"${match.group(2)}',
    );
    
    // Fix missing quotes after other datetime-like patterns
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'"(\\w+)":"(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})([},])'),
      (match) => '"${match.group(1)}":"${match.group(2)}"${match.group(3)}',
    );
    
    // Fix sequential objects without array wrapper
    // Pattern: },{"property should be }],[{"property (closing and opening array)
    // This happens when server sends multiple objects that should be in an array
    // For now, leave as-is since fixing this requires deep context analysis
    // The backend should fix the JSON structure
    
    return cleaned;
  }

  /// Extract offset from FormatException message
  int? _extractOffset(String message) {
    final match = RegExp(r'offset (\d+)').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Handle Dio errors
  void _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.data?['message'] ?? 'Unknown error';
      
      switch (statusCode) {
        case 400:
          throw Exception('Bad Request: $message');
        case 401:
          throw Exception('Unauthorized: Please login again');
        case 404:
          throw Exception('Not Found: $message');
        case 422:
          throw Exception('Validation Error: $message');
        case 500:
          throw Exception('Server Error: $message');
        default:
          throw Exception('Error $statusCode: $message');
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      throw Exception('Connection timeout. Please check your internet connection.');
    } else if (error.type == DioExceptionType.connectionError) {
      throw Exception('No internet connection');
    } else {
      throw Exception('An unexpected error occurred: ${error.message}');
    }
  }
}

/// Example traveler data structure
/// 
/// ```dart
/// final traveler = {
///   'id': '1',
///   'dateOfBirth': '1990-01-01',
///   'name': {
///     'firstName': 'JOHN',
///     'lastName': 'DOE',
///   },
///   'gender': 'MALE',
///   'contact': {
///     'emailAddress': 'john.doe@example.com',
///     'phones': [
///       {
///         'deviceType': 'MOBILE',
///         'countryCallingCode': '1',
///         'number': '1234567890',
///       },
///     ],
///   },
///   'documents': [
///     {
///       'documentType': 'PASSPORT',
///       'number': 'A12345678',
///       'expiryDate': '2030-12-31',
///       'issuanceCountry': 'US',
///       'nationality': 'US',
///       'holder': true,
///     },
///   ],
/// };
/// ```
