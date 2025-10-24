import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../widgets/package_search_widget.dart';
import 'search_results/flight_results_view.dart';
import 'search_results/hotel_results_view.dart';
import 'search_results/umrah_results_view.dart';

class SearchView extends StatefulWidget {
  final int initialTabIndex;
  final String fromText;
  final String toText;
  
  const SearchView({
    super.key,
    this.initialTabIndex = 0,
    this.fromText = '',
    this.toText = '',
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Flight Search Controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _passengers = 1;
  String _flightClass = 'Economy';
  bool _isRoundTrip = true;
  
  // Umrah Package Controllers
  final TextEditingController _umrahFromController = TextEditingController();
  DateTime? _umrahDepartureDate;
  int _umrahDuration = 14;
  String _umrahPackageType = 'Standard';
  
  // Hotel Search Controllers
  final TextEditingController _hotelDestinationController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 2;
  int _rooms = 1;
  String _hotelStarRating = 'Any';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    
    // Pre-fill form fields if provided
    if (widget.fromText.isNotEmpty) {
      _fromController.text = widget.fromText;
    }
    if (widget.toText.isNotEmpty) {
      _toController.text = widget.toText;
      _umrahFromController.text = widget.fromText; // Use from field for Umrah departure city
      _hotelDestinationController.text = widget.toText; // Use to field for hotel destination
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _umrahFromController.dispose();
    _hotelDestinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Search',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          indicatorWeight: 3,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.fadedTextColor,
          labelStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.bodyMedium,
          tabs: const [
            Tab(text: 'Umrah Packages'),
            Tab(text: 'Flights'),
            Tab(text: 'Hotels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab('Umrah Packages'),
          _buildSearchTab('Flights'),
          _buildSearchTab('Hotels'),
        ],
      ),
    );
  }

  Widget _buildSearchTab(String type) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          color: AppColors.dividerColor.withOpacity(0.05),
          child: Column(
            children: [
              if (type == 'Flights') _buildFlightForm(),
              if (type == 'Umrah Packages') _buildUmrahForm(),
              if (type == 'Hotels') _buildHotelForm(),
              const SizedBox(height: AppTheme.spacingMedium),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                  ),
                  onPressed: () => _performSearch(type),
                  child: Text(
                    'Search $type',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.backgroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: _buildRecommendedSection(type),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightForm() {
    return Column(
      children: [
        // Trip type selector
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('Round Trip', style: AppTheme.bodySmall),
                value: true,
                groupValue: _isRoundTrip,
                onChanged: (value) => setState(() => _isRoundTrip = value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('One Way', style: AppTheme.bodySmall),
                value: false,
                groupValue: _isRoundTrip,
                onChanged: (value) => setState(() => _isRoundTrip = value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        // From and To fields
        Row(
          children: [
            Expanded(
              child: _buildCompactField(
                controller: _fromController,
                label: 'From',
                hint: 'Departure city',
                icon: Icons.flight_takeoff,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildCompactField(
                controller: _toController,
                label: 'To',
                hint: 'Destination city',
                icon: Icons.flight_land,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        // Date fields
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Departure',
                date: _departureDate,
                onTap: () => _selectDate(context, true, 'flight'),
                icon: Icons.calendar_today,
              ),
            ),
            if (_isRoundTrip) ...[
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: _buildDateField(
                  label: 'Return',
                  date: _returnDate,
                  onTap: () => _selectDate(context, false, 'flight'),
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        // Passengers and Class
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Passengers',
                value: _passengers.toString(),
                items: List.generate(9, (i) => (i + 1).toString()),
                onChanged: (value) => setState(() => _passengers = int.parse(value!)),
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildDropdownField(
                label: 'Class',
                value: _flightClass,
                items: ['Economy', 'Premium', 'Business', 'First'],
                onChanged: (value) => setState(() => _flightClass = value!),
                icon: Icons.airline_seat_recline_normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUmrahForm() {
    return Column(
      children: [
        _buildCompactField(
          controller: _umrahFromController,
          label: 'Departure City',
          hint: 'Select departure city',
          icon: Icons.mosque,
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Departure Date',
                date: _umrahDepartureDate,
                onTap: () => _selectDate(context, true, 'umrah'),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildDropdownField(
                label: 'Duration (Days)',
                value: _umrahDuration.toString(),
                items: ['7', '14', '21', '30'],
                onChanged: (value) => setState(() => _umrahDuration = int.parse(value!)),
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        _buildDropdownField(
          label: 'Package Type',
          value: _umrahPackageType,
          items: ['Standard', 'Premium', 'Luxury', 'VIP'],
          onChanged: (value) => setState(() => _umrahPackageType = value!),
          icon: Icons.star,
        ),
      ],
    );
  }

  Widget _buildHotelForm() {
    return Column(
      children: [
        _buildCompactField(
          controller: _hotelDestinationController,
          label: 'Destination',
          hint: 'City or hotel name',
          icon: Icons.hotel,
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Check In',
                date: _checkInDate,
                onTap: () => _selectDate(context, true, 'hotel'),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildDateField(
                label: 'Check Out',
                date: _checkOutDate,
                onTap: () => _selectDate(context, false, 'hotel'),
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Guests',
                value: _guests.toString(),
                items: List.generate(8, (i) => (i + 1).toString()),
                onChanged: (value) => setState(() => _guests = int.parse(value!)),
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _buildDropdownField(
                label: 'Rooms',
                value: _rooms.toString(),
                items: List.generate(4, (i) => (i + 1).toString()),
                onChanged: (value) => setState(() => _rooms = int.parse(value!)),
                icon: Icons.bed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        _buildDropdownField(
          label: 'Star Rating',
          value: _hotelStarRating,
          items: ['Any', '3+ Stars', '4+ Stars', '5 Stars'],
          onChanged: (value) => setState(() => _hotelStarRating = value!),
          icon: Icons.star,
        ),
      ],
    );
  }

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        color: AppColors.backgroundColor,
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTheme.bodySmall.copyWith(
            color: AppColors.primaryColor,
            fontSize: 12,
          ),
          hintStyle: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSmall,
            vertical: AppTheme.spacingSmall,
          ),
          isDense: true,
        ),
      ),
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function() onTap,
    required IconData icon,
  }) {
    final displayText = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'Select Date';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          color: AppColors.backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSmall,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    displayText,
                    style: date == null
                        ? AppTheme.bodySmall.copyWith(
                            color: AppColors.fadedTextColor,
                            fontSize: 12,
                          )
                        : AppTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        color: AppColors.backgroundColor,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                  ),
                ),
                DropdownButton<String>(
                  value: value,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.fadedTextColor,
                  ),
                  iconSize: 24,
                  elevation: 16,
                  isDense: true,
                  style: AppTheme.bodyMedium,
                  underline: const SizedBox(),
                  onChanged: onChanged,
                  items: items.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch(String type) {
    // Navigate to dedicated results pages for each type
    switch (type) {
      case 'Flights':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FlightResultsView(
              from: _fromController.text,
              to: _toController.text,
              departureDate: _departureDate,
              returnDate: _isRoundTrip ? _returnDate : null,
              passengers: _passengers,
              flightClass: _flightClass,
              isRoundTrip: _isRoundTrip,
            ),
          ),
        );
        break;
      case 'Umrah Packages':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UmrahResultsView(
              departureCity: _umrahFromController.text,
              departureDate: _umrahDepartureDate,
              durationDays: _umrahDuration,
              packageType: _umrahPackageType,
            ),
          ),
        );
        break;
      case 'Hotels':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HotelResultsView(
              destination: _hotelDestinationController.text,
              checkIn: _checkInDate,
              checkOut: _checkOutDate,
              guests: _guests,
              rooms: _rooms,
              starRating: _hotelStarRating,
            ),
          ),
        );
        break;
    }
  }

  
  Future<void> _selectDate(BuildContext context, bool isStart, String type) async {
    final now = DateTime.now();
    final initialDate = now.add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (type == 'flight') {
          if (isStart) {
            _departureDate = picked;
          } else {
            _returnDate = picked;
          }
        } else if (type == 'umrah') {
          _umrahDepartureDate = picked;
        } else if (type == 'hotel') {
          if (isStart) {
            _checkInDate = picked;
          } else {
            _checkOutDate = picked;
          }
        }
      });
    }
  }
  
  Widget _buildRecommendedSection(String type) {
    // Placeholder recommended cards per tab type
    final List<Map<String, String>> items = type == 'Flights'
        ? [
            {
              'title': 'Discounted Flights',
              'subtitle': 'Save up to 30% on Addis to Dubai',
            },
            {
              'title': 'Weekend Getaways',
              'subtitle': 'Cheap flights this weekend',
            },
          ]
        : type == 'Hotels'
            ? [
                {
                  'title': 'Top Rated Hotels',
                  'subtitle': '4+ stars in your destination',
                },
                {
                  'title': 'Last Minute Deals',
                  'subtitle': 'Exclusive discounts tonight',
                },
              ]
            : [
                {
                  'title': 'Recommended Packages',
                  'subtitle': 'Popular Umrah packages',
                },
                {
                  'title': 'Family Packages',
                  'subtitle': 'Affordable options for families',
                },
              ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        ...items.map((e) => _buildRecommendedCard(e['title']!, e['subtitle']!)),
      ],
    );
  }
  
  Widget _buildRecommendedCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_offer, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTheme.fadedText),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.fadedTextColor),
        ],
      ),
    );
  }
}
