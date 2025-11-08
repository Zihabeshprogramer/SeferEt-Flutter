import '../models/hotel_models.dart';
import 'api_service.dart';

class HotelService {
  static final HotelService _instance = HotelService._internal();
  factory HotelService() => _instance;
  HotelService._internal();

  final ApiService _apiService = ApiService();

  /// Search for hotels
  /// Returns a list of hotels from both local and Amadeus sources
  /// Local hotels are returned first in the list
  Future<ApiResponse<List<Hotel>>> searchHotels(
    HotelSearchParams params,
  ) async {
    try {
      final queryParams = params.toQueryParams();
      print('🏨 Searching hotels with params: $queryParams');
      final response = await _apiService.get<Map<String, dynamic>>(
        '/hotels/search',
        queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
      );
      print('📡 Hotel search response: ${response.statusCode} - ${response.message}');

      if (response.success && response.data != null) {
        final data = response.data!;
        final hotelsJson = data['hotels'] as List? ?? data['data'] as List? ?? [];
        
        final hotels = hotelsJson
            .map((json) => Hotel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort: local hotels first, then Amadeus
        hotels.sort((a, b) {
          if (a.source == 'local' && b.source != 'local') return -1;
          if (a.source != 'local' && b.source == 'local') return 1;
          return 0;
        });

        return ApiResponse<List<Hotel>>(
          success: true,
          message: response.message,
          data: hotels,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<Hotel>>(
        success: false,
        message: response.message,
        data: [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<Hotel>>(
        success: false,
        message: 'Hotel API not available. Please ensure the backend endpoint /api/v1/hotels/search is configured.',
        data: [],
        statusCode: 0,
      );
    }
  }

  /// Get detailed information about a specific hotel
  Future<ApiResponse<Hotel>> getHotelDetails(String hotelId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/hotels/$hotelId',
      );

      if (response.success && response.data != null) {
        final hotelData = response.data!['hotel'] ?? response.data!['data'] ?? response.data;
        final hotel = Hotel.fromJson(hotelData as Map<String, dynamic>);

        return ApiResponse<Hotel>(
          success: true,
          message: response.message,
          data: hotel,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<Hotel>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Hotel>(
        success: false,
        message: 'Failed to get hotel details: $e',
        statusCode: 0,
      );
    }
  }

  /// Book a hotel
  /// For local hotels: creates a normal DB booking
  /// For Amadeus hotels: triggers Amadeus API booking through backend
  Future<ApiResponse<HotelBooking>> bookHotel(
    HotelBooking booking,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/hotels/book',
        booking.toJson(),
      );

      if (response.success && response.data != null) {
        final bookingData = response.data!['booking'] ?? response.data!['data'] ?? response.data;
        final confirmedBooking = HotelBooking.fromJson(
          bookingData as Map<String, dynamic>,
        );

        return ApiResponse<HotelBooking>(
          success: true,
          message: response.message,
          data: confirmedBooking,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<HotelBooking>(
        success: false,
        message: response.message,
        errors: response.errors,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<HotelBooking>(
        success: false,
        message: 'Failed to book hotel: $e',
        statusCode: 0,
      );
    }
  }

  /// Get hotel offers for a specific hotel
  Future<ApiResponse<List<HotelOffer>>> getHotelOffers(
    String hotelId,
    DateTime checkIn,
    DateTime checkOut,
    int adults,
  ) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/hotels/$hotelId/offers',
        queryParameters: {
          'check_in': checkIn.toIso8601String().split('T')[0],
          'check_out': checkOut.toIso8601String().split('T')[0],
          'adults': adults.toString(),
        },
      );

      if (response.success && response.data != null) {
        final offersJson = response.data!['offers'] as List? ?? response.data!['data'] as List? ?? [];
        
        final offers = offersJson
            .map((json) => HotelOffer.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<HotelOffer>>(
          success: true,
          message: response.message,
          data: offers,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<HotelOffer>>(
        success: false,
        message: response.message,
        data: [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<HotelOffer>>(
        success: false,
        message: 'Failed to get hotel offers: $e',
        data: [],
        statusCode: 0,
      );
    }
  }

  /// Get user's hotel bookings
  Future<ApiResponse<List<HotelBooking>>> getMyBookings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/hotels/bookings',
      );

      if (response.success && response.data != null) {
        final bookingsJson = response.data!['bookings'] as List? ?? response.data!['data'] as List? ?? [];
        
        final bookings = bookingsJson
            .map((json) => HotelBooking.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<HotelBooking>>(
          success: true,
          message: response.message,
          data: bookings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<HotelBooking>>(
        success: false,
        message: response.message,
        data: [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<HotelBooking>>(
        success: false,
        message: 'Failed to get bookings: $e',
        data: [],
        statusCode: 0,
      );
    }
  }

  /// Cancel a hotel booking
  Future<ApiResponse<void>> cancelBooking(String bookingId) async {
    try {
      final response = await _apiService.delete<void>(
        '/hotels/bookings/$bookingId',
      );

      return response;
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Failed to cancel booking: $e',
        statusCode: 0,
      );
    }
  }
}
