import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../models/hotel_models.dart';
import '../../../providers/hotel_provider.dart';
import '../../../core/widgets/city_autocomplete_field.dart';
import 'hotel_detail_page.dart';

class HotelListPage extends StatefulWidget {
  final String? cityCode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? adults;
  final int? rooms;

  const HotelListPage({
    super.key,
    this.cityCode,
    this.checkIn,
    this.checkOut,
    this.adults,
    this.rooms,
  });

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  final TextEditingController _cityController = TextEditingController();
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 3));
  int _adults = 2;
  int _rooms = 1;
  bool _hasSearched = false;
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    if (widget.cityCode != null) _cityController.text = widget.cityCode!;
    if (widget.checkIn != null) _checkInDate = widget.checkIn!;
    if (widget.checkOut != null) _checkOutDate = widget.checkOut!;
    if (widget.adults != null) _adults = widget.adults!;
    if (widget.rooms != null) _rooms = widget.rooms!;

    // Auto search if parameters provided
    if (widget.cityCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    // Use city code if selected, otherwise use city name
    final cityIdentifier = _selectedCity?.code ?? _cityController.text;

    final params = HotelSearchParams(
      cityCode: cityIdentifier,
      checkIn: _checkInDate,
      checkOut: _checkOutDate,
      adults: _adults,
      rooms: _rooms,
    );

    await context.read<HotelProvider>().searchHotels(params);
    setState(() {
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Search Hotels'),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: Consumer<HotelProvider>(
              builder: (context, provider, child) {
                if (!_hasSearched) {
                  return _buildInitialState();
                }

                if (provider.isSearching) {
                  return _buildLoadingState();
                }

                if (provider.searchState == HotelViewState.error) {
                  return _buildErrorState(provider.searchError ?? 'Failed to search hotels');
                }

                if (provider.searchState == HotelViewState.empty) {
                  return _buildEmptyState();
                }

                return _buildHotelsList(provider.filteredHotels);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CityAutocompleteField(
            controller: _cityController,
            label: 'Destination',
            hint: 'Where are you going?',
            icon: Icons.location_city,
            onCitySelected: (city) {
              setState(() {
                _selectedCity = city;
              });
            },
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Check-in',
                  date: _checkInDate,
                  onTap: _selectCheckIn,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: _buildDateButton(
                  label: 'Check-out',
                  date: _checkOutDate,
                  onTap: _selectCheckOut,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              Expanded(
                child: _buildCountButton('Adults', _adults, (val) => setState(() => _adults = val)),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: _buildCountButton('Rooms', _rooms, (val) => setState(() => _rooms = val)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
              ),
              child: const Text('Search Hotels'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          color: AppColors.backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM dd').format(date),
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountButton(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        color: AppColors.backgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  value.toString(),
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => onChanged(value + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel,
            size: 80,
            color: AppColors.fadedTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Search for hotels',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.fadedTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Enter a city to find the best hotel deals',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.fadedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryColor),
          SizedBox(height: AppTheme.spacingMedium),
          Text('Searching for hotels...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              error,
              style: AppTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.fadedTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'No hotels found',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.fadedTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Try adjusting your search criteria',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.fadedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsList(List<Hotel> hotels) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          color: AppColors.lightgrayBackground,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${hotels.length} hotel${hotels.length != 1 ? 's' : ''} found',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Consumer<HotelProvider>(
                builder: (context, provider, child) {
                  return PopupMenuButton<String>(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sort: ${_getSortLabel(provider.sortBy)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                    onSelected: (value) {
                      provider.updateSort(value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'price', child: Text('Price: Low to High')),
                      const PopupMenuItem(value: 'rating', child: Text('Rating: High to Low')),
                      const PopupMenuItem(value: 'distance', child: Text('Distance')),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              return _buildHotelCard(hotels[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HotelDetailPage(
                hotelId: hotel.id,
                hotel: hotel,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.borderRadiusMedium),
                ),
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Stack(
                children: [
                  if (hotel.imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: hotel.imageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.hotel, size: 48, color: AppColors.primaryColor),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.hotel, size: 48, color: AppColors.primaryColor),
                    ),
                  if (hotel.isAmadeus)
                    Positioned(
                      top: AppTheme.spacingSmall,
                      right: AppTheme.spacingSmall,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSmall,
                          vertical: AppTheme.spacingXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flight_takeoff,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Amadeus',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Hotel Details
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: AppTheme.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < hotel.rating ? Icons.star : Icons.star_border,
                                  color: AppColors.warningColor,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      if (hotel.lowestPrice != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${hotel.lowestPrice!.toStringAsFixed(0)}',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'per night',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.fadedTextColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.fadedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.displayLocation,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.fadedTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (hotel.distance != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hotel.distanceText,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (hotel.guestRating != null) ...[
                    const SizedBox(height: AppTheme.spacingSmall),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hotel.guestRating!.toStringAsFixed(1),
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (hotel.reviewCount != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${hotel.reviewCount} reviews)',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.fadedTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (hotel.amenities.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSmall),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: hotel.amenities.take(4).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            amenity,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<HotelProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Hotels',
                    style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text('Source', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Wrap(
                    spacing: AppTheme.spacingSmall,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: provider.sourceFilter == null,
                        onSelected: (selected) {
                          provider.updateFilters(sourceFilter: null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Local Providers'),
                        selected: provider.sourceFilter == 'local',
                        onSelected: (selected) {
                          provider.updateFilters(sourceFilter: selected ? 'local' : null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Amadeus'),
                        selected: provider.sourceFilter == 'amadeus',
                        onSelected: (selected) {
                          provider.updateFilters(sourceFilter: selected ? 'amadeus' : null);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price':
        return 'Price';
      case 'rating':
        return 'Rating';
      case 'distance':
        return 'Distance';
      default:
        return 'Default';
    }
  }

  Future<void> _selectCheckIn() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate.add(const Duration(days: 1)))) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOut() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }
}
