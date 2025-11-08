import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../models/flight_models.dart';
import '../../../services/api_service.dart';
import '../../../../services/amadeus_flight_service.dart';
import 'flight_booking_page.dart';
import '../widgets/flight_result_card.dart';

class FlightResultsView extends StatefulWidget {
  final String from;
  final String to;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int passengers;
  final String flightClass;
  final bool isRoundTrip;

  const FlightResultsView({
    super.key,
    required this.from,
    required this.to,
    this.departureDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
    required this.isRoundTrip,
  });

  @override
  State<FlightResultsView> createState() => _FlightResultsViewState();
}

class _FlightResultsViewState extends State<FlightResultsView>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late final AmadeusFlightService _flightService;
  late TabController _tabController;

  List<FlightOffer> _flights = [];
  List<FlightOffer> _filteredFlights = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<DateTime> _dateTabs = [];
  int _selectedDateIndex = 0;
  FlightOffer? _selectedFlight;
  
  // Cache for prices per date
  final Map<String, double?> _datePrices = {};
  final Map<String, String?> _dateCurrencies = {};
  bool _isFetchingPrices = false;
  
  // Filter state
  double _minPrice = 0;
  double _maxPrice = 50000;
  Set<String> _selectedAirlines = {};
  int? _selectedStops; // null = any, 0 = non-stop, 1 = 1 stop, 2 = 2+ stops
  double _maxDuration = 24; // hours
  TimeOfDay _earliestDeparture = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _latestDeparture = const TimeOfDay(hour: 23, minute: 59);
  String _sortBy = 'price_asc'; // price_asc, price_desc, duration, departure
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _flightService = AmadeusFlightService(
      baseUrl: 'http://172.20.10.9:8000',
    );
    _initializeDateTabs();
    _tabController = TabController(
      length: _dateTabs.length,
      vsync: this,
      initialIndex: _selectedDateIndex,
    );
    _tabController.addListener(_onTabChanged);
    _fetchFlights();
    // Delay background price fetching to prioritize main flight fetch
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _fetchAllDatePrices();
      }
    });
  }

  void _initializeDateTabs() {
    final baseDate = widget.departureDate ?? DateTime.now();
    _generateDateTabsAroundDate(baseDate);
  }
  
  void _generateDateTabsAroundDate(DateTime centerDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    final List<DateTime> dates = [];
    int beforeDatesAdded = 0;
    
    // Try to add 2 dates before (if they're >= today)
    for (int i = 2; i > 0; i--) {
      final date = centerDate.subtract(Duration(days: i));
      if (date.isAfter(todayOnly) || date.isAtSameMomentAs(todayOnly)) {
        dates.add(date);
        beforeDatesAdded++;
      }
    }
    
    // Add center date
    dates.add(centerDate);
    
    // Add future dates to ensure we always have 6 total tabs
    // If we couldn't add 2 before dates, add extra after dates
    final afterDatesToAdd = 5 - beforeDatesAdded; // Always aim for 6 total tabs
    for (int i = 1; i <= afterDatesToAdd; i++) {
      dates.add(centerDate.add(Duration(days: i)));
    }
    
    _dateTabs = dates;
    // Center date is at the position after all the before dates
    _selectedDateIndex = beforeDatesAdded;
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newSelectedDate = _dateTabs[_tabController.index];
      
      // Regenerate dates around the new selected date
      _generateDateTabsAroundDate(newSelectedDate);
      
      // Defer disposal until after the notification completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        final oldController = _tabController;
        
        // Create new tab controller
        _tabController = TabController(
          length: _dateTabs.length,
          vsync: this,
          initialIndex: _selectedDateIndex,
        );
        _tabController.addListener(_onTabChanged);
        
        // Dispose old controller after new one is set up
        oldController.removeListener(_onTabChanged);
        oldController.dispose();
        
        setState(() {});
      });
      
      _fetchFlights();
      
      // Fetch prices for the new date tabs after a short delay
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          _fetchAllDatePrices();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFlights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedFlight = null;
    });

    try {
      final token = _apiService.authToken ?? '';
      final dateFormat = DateFormat('yyyy-MM-dd');
      final selectedDate = _dateTabs[_selectedDateIndex];

      final result = await _flightService.searchFlights(
        origin: widget.from,
        destination: widget.to,
        departureDate: dateFormat.format(selectedDate),
        returnDate: widget.returnDate != null
            ? dateFormat.format(widget.returnDate!)
            : null,
        adults: widget.passengers,
        token: token,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];

        // Handle both List and single item responses
        final List<dynamic> flightsList;
        if (data is List) {
          flightsList = data;
        } else if (data is Map) {
          flightsList = [data];
        } else {
          flightsList = [];
        }

        // Parse flights with error handling for each item
        final List<FlightOffer> parsedFlights = [];
        for (var i = 0; i < flightsList.length; i++) {
          try {
            final flightData = flightsList[i] as Map<String, dynamic>;
            parsedFlights.add(FlightOffer.fromJson(flightData));
          } catch (parseError) {
            debugPrint('Error parsing flight at index $i: $parseError');
            // Continue with other flights
          }
        }

        setState(() {
          _flights = parsedFlights;
          _applyFilters(); // Apply filters to new flight data
          _isLoading = false;
          if (parsedFlights.isEmpty && flightsList.isNotEmpty) {
            _errorMessage = 'Could not parse flight data. Please try again.';
          }
          
          // Cache the price for this date
          if (parsedFlights.isNotEmpty) {
            final dateKey = dateFormat.format(selectedDate);
            final minPrice = parsedFlights.map((e) => e.price.total).reduce((a, b) => a < b ? a : b);
            _datePrices[dateKey] = minPrice;
            _dateCurrencies[dateKey] = parsedFlights.first.price.currency;
            
            // Reset price range based on new flights to avoid RangeSlider assertion errors
            final prices = parsedFlights.map((e) => e.price.total).toList();
            final newMin = prices.reduce((a, b) => a < b ? a : b);
            final newMax = prices.reduce((a, b) => a > b ? a : b);
            
            // Only update if current values are outside the new range
            if (_minPrice < newMin || _minPrice > newMax) {
              _minPrice = newMin;
            }
            if (_maxPrice > newMax || _maxPrice < newMin) {
              _maxPrice = newMax;
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'] as String? ?? 'No flights found';
          _flights = [];
          _isLoading = false;
        });
      }
    } on FormatException catch (e) {
      debugPrint('JSON Format Error: $e');
      setState(() {
        _errorMessage = 'Invalid response from server. Please try again.';
        _flights = [];
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching flights: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString().contains('FormatException')
            ? 'Invalid response from server'
            : 'Failed to load flights: ${e.toString()}';
        _flights = [];
        _isLoading = false;
      });
    }
  }

  // Apply filters to flight list
  void _applyFilters() {
    List<FlightOffer> filtered = List.from(_flights);
    
    // Filter by price
    filtered = filtered.where((flight) {
      return flight.price.total >= _minPrice && flight.price.total <= _maxPrice;
    }).toList();
    
    // Filter by airlines
    if (_selectedAirlines.isNotEmpty) {
      filtered = filtered.where((flight) {
        final airline = flight.itineraries.first.segments.first.carrierCode;
        return _selectedAirlines.contains(airline);
      }).toList();
    }
    
    // Filter by stops
    if (_selectedStops != null) {
      filtered = filtered.where((flight) {
        final stops = flight.itineraries.first.segments.length - 1;
        if (_selectedStops == 0) {
          return stops == 0;
        } else if (_selectedStops == 1) {
          return stops == 1;
        } else {
          return stops >= 2;
        }
      }).toList();
    }
    
    // Filter by duration
    filtered = filtered.where((flight) {
      final duration = _getDurationInHours(flight.itineraries.first.duration);
      return duration <= _maxDuration;
    }).toList();
    
    // Filter by departure time
    filtered = filtered.where((flight) {
      final departureTime = DateTime.parse(flight.itineraries.first.segments.first.departureTime);
      final flightTime = TimeOfDay(hour: departureTime.hour, minute: departureTime.minute);
      final earliestMinutes = _earliestDeparture.hour * 60 + _earliestDeparture.minute;
      final latestMinutes = _latestDeparture.hour * 60 + _latestDeparture.minute;
      final flightMinutes = flightTime.hour * 60 + flightTime.minute;
      return flightMinutes >= earliestMinutes && flightMinutes <= latestMinutes;
    }).toList();
    
    // Sort
    filtered = _sortFlights(filtered);
    
    _filteredFlights = filtered;
    _hasActiveFilters = _isFilterActive();
  }
  
  // Check if any filter is active
  bool _isFilterActive() {
    if (_flights.isEmpty) return false;
    final prices = _flights.map((e) => e.price.total).toList();
    final defaultMin = prices.reduce((a, b) => a < b ? a : b);
    final defaultMax = prices.reduce((a, b) => a > b ? a : b);
    
    return _minPrice > defaultMin ||
        _maxPrice < defaultMax ||
        _selectedAirlines.isNotEmpty ||
        _selectedStops != null ||
        _maxDuration < 24 ||
        _earliestDeparture.hour != 0 ||
        _earliestDeparture.minute != 0 ||
        _latestDeparture.hour != 23 ||
        _latestDeparture.minute != 59;
  }
  
  // Sort flights based on selected criteria
  List<FlightOffer> _sortFlights(List<FlightOffer> flights) {
    final sorted = List<FlightOffer>.from(flights);
    
    switch (_sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => a.price.total.compareTo(b.price.total));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.price.total.compareTo(a.price.total));
        break;
      case 'duration':
        sorted.sort((a, b) {
          final durationA = _getDurationInHours(a.itineraries.first.duration);
          final durationB = _getDurationInHours(b.itineraries.first.duration);
          return durationA.compareTo(durationB);
        });
        break;
      case 'departure':
        sorted.sort((a, b) {
          final depA = DateTime.parse(a.itineraries.first.segments.first.departureTime);
          final depB = DateTime.parse(b.itineraries.first.segments.first.departureTime);
          return depA.compareTo(depB);
        });
        break;
    }
    
    return sorted;
  }
  
  // Get duration in hours from ISO 8601 duration string
  double _getDurationInHours(String isoDuration) {
    final hoursMatch = RegExp(r'(\d+)H').firstMatch(isoDuration);
    final minutesMatch = RegExp(r'(\d+)M').firstMatch(isoDuration);
    final hours = hoursMatch != null ? int.parse(hoursMatch.group(1)!) : 0;
    final minutes = minutesMatch != null ? int.parse(minutesMatch.group(1)!) : 0;
    return hours + (minutes / 60);
  }
  
  // Get unique airlines from current flights
  Set<String> _getAvailableAirlines() {
    return _flights
        .map((flight) => flight.itineraries.first.segments.first.carrierCode)
        .toSet();
  }
  
  // Clear all filters
  void _clearFilters() {
    setState(() {
      if (_flights.isNotEmpty) {
        final prices = _flights.map((e) => e.price.total).toList();
        _minPrice = prices.reduce((a, b) => a < b ? a : b);
        _maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
      _selectedAirlines.clear();
      _selectedStops = null;
      _maxDuration = 24;
      _earliestDeparture = const TimeOfDay(hour: 0, minute: 0);
      _latestDeparture = const TimeOfDay(hour: 23, minute: 59);
      _sortBy = 'price_asc';
      _applyFilters();
    });
  }

  // Fetch prices for all dates in the background using batch request
  Future<void> _fetchAllDatePrices() async {
    if (_isFetchingPrices) return; // Prevent multiple simultaneous fetches
    _isFetchingPrices = true;
    
    final token = _apiService.authToken ?? '';
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    try {
      // Get dates that don't have prices yet
      final datesToFetch = _dateTabs
          .where((date) => !_datePrices.containsKey(dateFormat.format(date)))
          .map((date) => dateFormat.format(date))
          .toList();
      
      if (datesToFetch.isEmpty) {
        _isFetchingPrices = false;
        return;
      }
      
      debugPrint('🚀 Batch fetching prices for ${datesToFetch.length} dates: $datesToFetch');
      
      // Make batch request
      final batchResults = await _flightService.searchFlightsBatch(
        origin: widget.from,
        destination: widget.to,
        departureDates: datesToFetch,
        returnDate: widget.returnDate != null
            ? dateFormat.format(widget.returnDate!)
            : null,
        adults: widget.passengers,
        token: token,
      ).timeout(
        Duration(seconds: 90),
        onTimeout: () {
          debugPrint('⏱️ Timeout fetching batch prices');
          return {};
        },
      );
      
      debugPrint('📦 Batch results received: ${batchResults.length} dates');
      debugPrint('Batch result keys: ${batchResults.keys.toList()}');
      
      // Process batch results
      for (var entry in batchResults.entries) {
        final dateKey = entry.key;
        final dateData = entry.value;
        
        try {
          debugPrint('📊 Processing date $dateKey: success=${dateData['success']}, has data=${dateData['data'] != null}');
          
          if (dateData['success'] == true && dateData['data'] != null) {
            final data = dateData['data'];
            final List<dynamic> flightsList;
            
            if (data is List) {
              flightsList = data;
            } else if (data is Map) {
              flightsList = [data];
            } else {
              debugPrint('⚠️ Unexpected data format for $dateKey: ${data.runtimeType}');
              continue;
            }
            
            debugPrint('✈️ Found ${flightsList.length} flights for $dateKey');
            
            final List<FlightOffer> parsedFlights = [];
            for (var flightData in flightsList) {
              try {
                parsedFlights.add(FlightOffer.fromJson(flightData as Map<String, dynamic>));
              } catch (e) {
                debugPrint('❌ Error parsing flight for $dateKey: $e');
              }
            }
            
            if (parsedFlights.isNotEmpty) {
              final minPrice = parsedFlights.map((e) => e.price.total).reduce((a, b) => a < b ? a : b);
              debugPrint('💰 Min price for $dateKey: ${parsedFlights.first.price.currency} $minPrice');
              if (mounted) {
                setState(() {
                  _datePrices[dateKey] = minPrice;
                  _dateCurrencies[dateKey] = parsedFlights.first.price.currency;
                });
              }
            } else {
              debugPrint('⚠️ No valid flights parsed for $dateKey');
            }
          } else {
            debugPrint('❌ Date $dateKey failed or no data: ${dateData['message'] ?? 'Unknown error'}');
          }
        } catch (e) {
          debugPrint('Error processing date $dateKey: $e');
        }
      }
      
      debugPrint('✅ Batch fetch complete: ${batchResults.length} dates processed');
    } catch (e) {
      debugPrint('Error in batch fetch: $e');
    } finally {
      _isFetchingPrices = false;
    }
  }

  String _formatDuration(String isoDuration) {
    final hours = RegExp(r'(\d+)H').firstMatch(isoDuration)?.group(1) ?? '0';
    final minutes = RegExp(r'(\d+)M').firstMatch(isoDuration)?.group(1) ?? '0';
    return '${hours}h ${minutes}m';
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDate(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('E dd, MMM').format(dateTime);
  }

  double _getTotalPrice(FlightOffer offer) {
    return offer.price.total * widget.passengers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leadingWidth: 70,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all(AppColors.backgroundColor),
          ),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Flight Search',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.backgroundColor,
          ),
        ),
        actions: [
          if (!_isLoading && _errorMessage == null && _flights.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: _showFilterBottomSheet,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(AppColors.backgroundColor),
                    ),
                    icon: const Icon(
                      Icons.tune,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Flight Route Info Section
                _buildRouteHeader(),
                const SizedBox(height: 16),

                // Date Selector Tabs
                _buildDateTabs(),
                const SizedBox(height: 16),

                // Flight Results List
                Expanded(
                  child: _isLoading
                      ? _buildLoadingView()
                      : _errorMessage != null
                          ? _buildErrorView()
                      : _filteredFlights.isEmpty
                              ? _buildNoResultsView()
                              : _buildFlightsList(),
                ),
              ],
            ),
            // Book Now Button (Persistent at bottom when flight selected)
            if (_selectedFlight != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: () => _bookSelectedFlight(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Book Now - ${_selectedFlight!.price.currency} ${_selectedFlight!.price.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Origin',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.backgroundColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.from,
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.backgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CustomPaint(
                  size: const Size(200, 70),
                  painter: FlightDurationHeaderPainter(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Destination',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.backgroundColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.to,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_flights.isNotEmpty)
              Center(
                child: Text(
                  '${_flights[0].price.currency} ${_flights.map((e) => e.price.total).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 26,
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Current Cheapest Price',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.backgroundColor.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabAlignment: TabAlignment.center,
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          tabs: _dateTabs.asMap().entries.map((entry) {
            final date = entry.value;
            final formatted = DateFormat('dd, MMM').format(date);
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            final price = _datePrices[dateKey];
            final currency = _dateCurrencies[dateKey];
            final isSelected = _selectedDateIndex == entry.key;
            
            return SizedBox(
              width: 95,
              child: Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatted,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: isSelected ? 13 : 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (price != null && currency != null)
                      Text(
                        '$currency ${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.green[700] : Colors.green[200],
                        ),
                      )
                    else
                      SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSelected ? Colors.grey[600]! : Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color:  AppColors.lightgrayBackground, // Light gray background
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text(
              'Searching flights...',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: AppColors.lightgrayBackground, // Light gray background
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Flights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: AppColors.fadedTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchFlights,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Container(
      color: AppColors.lightgrayBackground, // Light gray background
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, size: 64, color: AppColors.fadedTextColor),
            SizedBox(height: 16),
            Text(
              'No Flights Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different dates or adjust your search',
              style: TextStyle(color: AppColors.fadedTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightsList() {
    return Container(
      color: const Color(0xFFF5F5F5), // Light gray background
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 0,
          right: 0,
          top: 8,
          bottom: _selectedFlight != null ? 100 : 8,
        ),
        itemCount: _filteredFlights.length,
        itemBuilder: (context, index) {
          final flight = _filteredFlights[index];
          return FlightResultCard(
            offer: flight,
            isSelected: _selectedFlight == flight,
            onTap: () {
              setState(() {
                if (_selectedFlight == flight) {
                  _selectedFlight = null;
                } else {
                  _selectedFlight = flight;
                }
              });
            },
            onViewDetails: () => _showFlightDetails(flight),
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    // Create local copies for the filter UI
    double tempMinPrice = _minPrice;
    double tempMaxPrice = _maxPrice;
    Set<String> tempSelectedAirlines = Set.from(_selectedAirlines);
    int? tempSelectedStops = _selectedStops;
    double tempMaxDuration = _maxDuration;
    TimeOfDay tempEarliestDeparture = _earliestDeparture;
    TimeOfDay tempLatestDeparture = _latestDeparture;
    String tempSortBy = _sortBy;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    const Expanded(
                      child: Text(
                        'Filter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${tempMinPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '\$${tempMaxPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: RangeValues(tempMinPrice, tempMaxPrice),
                        min: _flights.isNotEmpty 
                            ? _flights.map((e) => e.price.total).reduce((a, b) => a < b ? a : b) 
                            : 0,
                        max: _flights.isNotEmpty 
                            ? _flights.map((e) => e.price.total).reduce((a, b) => a > b ? a : b) 
                            : 10000,
                        divisions: 100,
                        activeColor: AppColors.primaryColor,
                        onChanged: (values) {
                          setModalState(() {
                            tempMinPrice = values.start;
                            tempMaxPrice = values.end;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Airlines
                      const Text(
                        'Airlines',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getAvailableAirlines().map((airline) {
                          final isSelected = tempSelectedAirlines.contains(airline);
                          return FilterChip(
                            label: Text(airline),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  tempSelectedAirlines.add(airline);
                                } else {
                                  tempSelectedAirlines.remove(airline);
                                }
                              });
                            },
                            selectedColor: AppColors.primaryColor.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Stops
                      const Text(
                        'Stops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Any'),
                            selected: tempSelectedStops == null,
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedStops = null;
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSelectedStops == null ? Colors.white : Colors.black87,
                              fontWeight: tempSelectedStops == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Non-stop'),
                            selected: tempSelectedStops == 0,
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedStops = 0;
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSelectedStops == 0 ? Colors.white : Colors.black87,
                              fontWeight: tempSelectedStops == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('1 Stop'),
                            selected: tempSelectedStops == 1,
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedStops = 1;
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSelectedStops == 1 ? Colors.white : Colors.black87,
                              fontWeight: tempSelectedStops == 1 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('2+ Stops'),
                            selected: tempSelectedStops == 2,
                            onSelected: (selected) {
                              setModalState(() {
                                tempSelectedStops = 2;
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSelectedStops == 2 ? Colors.white : Colors.black87,
                              fontWeight: tempSelectedStops == 2 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Duration
                      const Text(
                        'Max Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${tempMaxDuration.toStringAsFixed(0)} hours',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: tempMaxDuration,
                        min: 1,
                        max: 24,
                        divisions: 23,
                        activeColor: AppColors.primaryColor,
                        onChanged: (value) {
                          setModalState(() {
                            tempMaxDuration = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Sort By
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Price: Low → High'),
                            selected: tempSortBy == 'price_asc',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSortBy = 'price_asc';
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSortBy == 'price_asc' ? Colors.white : Colors.black87,
                              fontWeight: tempSortBy == 'price_asc' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Price: High → Low'),
                            selected: tempSortBy == 'price_desc',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSortBy = 'price_desc';
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSortBy == 'price_desc' ? Colors.white : Colors.black87,
                              fontWeight: tempSortBy == 'price_desc' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Duration: Shortest'),
                            selected: tempSortBy == 'duration',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSortBy = 'duration';
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSortBy == 'duration' ? Colors.white : Colors.black87,
                              fontWeight: tempSortBy == 'duration' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Departure: Earliest'),
                            selected: tempSortBy == 'departure',
                            onSelected: (selected) {
                              setModalState(() {
                                tempSortBy = 'departure';
                              });
                            },
                            selectedColor: AppColors.primaryColor,
                            labelStyle: TextStyle(
                              color: tempSortBy == 'departure' ? Colors.white : Colors.black87,
                              fontWeight: tempSortBy == 'departure' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _minPrice = tempMinPrice;
                              _maxPrice = tempMaxPrice;
                              _selectedAirlines = tempSelectedAirlines;
                              _selectedStops = tempSelectedStops;
                              _maxDuration = tempMaxDuration;
                              _earliestDeparture = tempEarliestDeparture;
                              _latestDeparture = tempLatestDeparture;
                              _sortBy = tempSortBy;
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFlightDetails(FlightOffer offer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildFlightDetailBottomSheet(offer),
    );
  }

  Widget _buildFlightDetailBottomSheet(FlightOffer offer) {
    final firstSegment = offer.itineraries.first.segments.first;
    final lastSegment = offer.itineraries.first.segments.last;
    final departureTime = _formatTime(firstSegment.departureTime);
    final arrivalTime = _formatTime(lastSegment.arrivalTime);
    final departureDate = _formatDate(firstSegment.departureTime);
    final arrivalDate = _formatDate(lastSegment.arrivalTime);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Airline info
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flight,
                  color: AppColors.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                firstSegment.carrierCode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Flight Details
          ListTile(
            leading: const Icon(Icons.flight_takeoff),
            title: Text(
                'Departure: ${firstSegment.departure} ($departureTime)'),
          ),
          ListTile(
            leading: const Icon(Icons.flight_land),
            title:
                Text('Arrival: ${lastSegment.arrival} ($arrivalTime)'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Travel Date: $departureDate to $arrivalDate'),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text('Duration: ${_formatDuration(offer.itineraries.first.duration)}'),
          ),
          ListTile(
            leading: const Icon(Icons.sync_alt),
            title: Text('Stops: ${offer.itineraries.first.stopsText}'),
          ),
          const Divider(),
          // Pricing
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(
              'Total Price: ${offer.price.currency} ${_getTotalPrice(offer).toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(height: 20),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedFlight = offer;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text(
                    'Select Flight',
                    style: TextStyle(color: AppColors.backgroundColor),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  void _bookSelectedFlight() {
    if (_selectedFlight != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlightBookingPage(
            offer: _selectedFlight!,
            passengers: widget.passengers,
          ),
        ),
      );
    }
  }
}

// Custom Painters
class FlightDurationHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Draw the curved dashed line
    for (double i = 0; i < size.width; i += 10) {
      path.moveTo(i, _curveY(i, size.width, size.height));
      path.lineTo(i + 5, _curveY(i + 5, size.width, size.height));
    }

    canvas.drawPath(path, paint);

    // Draw small circles at the start and end
    final startPoint = Offset(0, _curveY(0, size.width, size.height));
    final endPoint =
        Offset(size.width, _curveY(size.width, size.width, size.height));
    canvas.drawCircle(startPoint, 4, Paint()..color = Colors.white);
    canvas.drawCircle(endPoint, 4, Paint()..color = Colors.white);

    // Draw airplane icon
    final icon = Icons.airplanemode_active.codePoint;
    final airplaneOffset = Offset(
      size.width / 2,
      _curveY(size.width / 2, size.width, size.height),
    );

    canvas.save();
    canvas.translate(airplaneOffset.dx, airplaneOffset.dy);
    canvas.rotate(1.6);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon),
        style: TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontFamily: Icons.airplanemode_active.fontFamily,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();

    // Draw text below airplane
    const priceTracking = TextSpan(
      text: "Price Tracking",
      style: TextStyle(color: Colors.white, fontSize: 16),
    );
    final priceTrackingPainter = TextPainter(
      text: priceTracking,
      textDirection: ui.TextDirection.ltr,
    );
    priceTrackingPainter.layout();
    priceTrackingPainter.paint(
      canvas,
      Offset(
        size.width / 2 - priceTrackingPainter.width / 2,
        _curveY(size.width / 2, size.width, size.height) + 20,
      ),
    );
  }

  double _curveY(double x, double width, double height) {
    final normalizedX = x / width * 2 - 1;
    final maxHeight = height / 2;
    return maxHeight - 50 * (1 - normalizedX * normalizedX);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

