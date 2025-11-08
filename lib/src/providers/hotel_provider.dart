import 'package:flutter/foundation.dart';
import '../models/hotel_models.dart';
import '../services/hotel_service.dart';

enum HotelViewState {
  initial,
  loading,
  success,
  error,
  empty,
}

class HotelProvider with ChangeNotifier {
  final HotelService _hotelService = HotelService();

  // Search state
  HotelViewState _searchState = HotelViewState.initial;
  List<Hotel> _hotels = [];
  String? _searchError;
  HotelSearchParams? _lastSearchParams;

  // Detail state
  HotelViewState _detailState = HotelViewState.initial;
  Hotel? _selectedHotel;
  String? _detailError;

  // Booking state
  HotelViewState _bookingState = HotelViewState.initial;
  HotelBooking? _confirmedBooking;
  String? _bookingError;

  // Filters
  int? _minPrice;
  int? _maxPrice;
  int? _minRating;
  String? _sourceFilter; // 'local', 'amadeus', or null
  String _sortBy = 'price'; // 'price', 'rating', 'distance'

  // Getters
  HotelViewState get searchState => _searchState;
  List<Hotel> get hotels => _hotels;
  List<Hotel> get filteredHotels => _applyFiltersAndSort();
  String? get searchError => _searchError;
  HotelSearchParams? get lastSearchParams => _lastSearchParams;

  HotelViewState get detailState => _detailState;
  Hotel? get selectedHotel => _selectedHotel;
  String? get detailError => _detailError;

  HotelViewState get bookingState => _bookingState;
  HotelBooking? get confirmedBooking => _confirmedBooking;
  String? get bookingError => _bookingError;

  int? get minPrice => _minPrice;
  int? get maxPrice => _maxPrice;
  int? get minRating => _minRating;
  String? get sourceFilter => _sourceFilter;
  String get sortBy => _sortBy;

  bool get isSearching => _searchState == HotelViewState.loading;
  bool get isLoadingDetails => _detailState == HotelViewState.loading;
  bool get isBooking => _bookingState == HotelViewState.loading;

  /// Search for hotels
  Future<void> searchHotels(HotelSearchParams params) async {
    _searchState = HotelViewState.loading;
    _searchError = null;
    _lastSearchParams = params;
    notifyListeners();

    try {
      final response = await _hotelService.searchHotels(params);

      if (response.success && response.data != null) {
        _hotels = response.data!;
        _searchState = _hotels.isEmpty
            ? HotelViewState.empty
            : HotelViewState.success;
      } else {
        _searchError = response.message;
        _searchState = HotelViewState.error;
        _hotels = [];
      }
    } catch (e) {
      _searchError = 'Failed to search hotels: $e';
      _searchState = HotelViewState.error;
      _hotels = [];
    }

    notifyListeners();
  }

  /// Get hotel details
  Future<void> getHotelDetails(String hotelId) async {
    _detailState = HotelViewState.loading;
    _detailError = null;
    _selectedHotel = null;
    notifyListeners();

    try {
      final response = await _hotelService.getHotelDetails(hotelId);

      if (response.success && response.data != null) {
        _selectedHotel = response.data;
        _detailState = HotelViewState.success;
      } else {
        _detailError = response.message;
        _detailState = HotelViewState.error;
      }
    } catch (e) {
      _detailError = 'Failed to get hotel details: $e';
      _detailState = HotelViewState.error;
    }

    notifyListeners();
  }

  /// Book a hotel
  Future<bool> bookHotel(HotelBooking booking) async {
    _bookingState = HotelViewState.loading;
    _bookingError = null;
    _confirmedBooking = null;
    notifyListeners();

    try {
      final response = await _hotelService.bookHotel(booking);

      if (response.success && response.data != null) {
        _confirmedBooking = response.data;
        _bookingState = HotelViewState.success;
        notifyListeners();
        return true;
      } else {
        _bookingError = response.message;
        if (response.errors != null) {
          _bookingError = '$_bookingError\n${response.errors}';
        }
        _bookingState = HotelViewState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _bookingError = 'Failed to book hotel: $e';
      _bookingState = HotelViewState.error;
      notifyListeners();
      return false;
    }
  }

  /// Apply filters and sorting
  List<Hotel> _applyFiltersAndSort() {
    var result = List<Hotel>.from(_hotels);

    // Apply price filter
    if (_minPrice != null || _maxPrice != null) {
      result = result.where((hotel) {
        final price = hotel.lowestPrice;
        if (price == null) return false;
        if (_minPrice != null && price < _minPrice!) return false;
        if (_maxPrice != null && price > _maxPrice!) return false;
        return true;
      }).toList();
    }

    // Apply rating filter
    if (_minRating != null) {
      result = result.where((hotel) => hotel.rating >= _minRating!).toList();
    }

    // Apply source filter
    if (_sourceFilter != null) {
      result = result.where((hotel) => hotel.source == _sourceFilter).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price':
        result.sort((a, b) {
          final priceA = a.lowestPrice ?? double.infinity;
          final priceB = b.lowestPrice ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'distance':
        result.sort((a, b) {
          final distA = a.distance ?? double.infinity;
          final distB = b.distance ?? double.infinity;
          return distA.compareTo(distB);
        });
        break;
    }

    return result;
  }

  /// Update filters
  void updateFilters({
    int? minPrice,
    int? maxPrice,
    int? minRating,
    String? sourceFilter,
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    _sourceFilter = sourceFilter;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _sourceFilter = null;
    notifyListeners();
  }

  /// Update sort order
  void updateSort(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  /// Clear search results
  void clearSearch() {
    _hotels = [];
    _searchState = HotelViewState.initial;
    _searchError = null;
    _lastSearchParams = null;
    notifyListeners();
  }

  /// Clear hotel details
  void clearDetails() {
    _selectedHotel = null;
    _detailState = HotelViewState.initial;
    _detailError = null;
    notifyListeners();
  }

  /// Clear booking state
  void clearBooking() {
    _confirmedBooking = null;
    _bookingState = HotelViewState.initial;
    _bookingError = null;
    notifyListeners();
  }

  /// Reset all state
  void reset() {
    clearSearch();
    clearDetails();
    clearBooking();
    clearFilters();
    _sortBy = 'price';
    notifyListeners();
  }
}
