import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class HotelSearchView extends StatefulWidget {
  const HotelSearchView({super.key});

  @override
  State<HotelSearchView> createState() => _HotelSearchViewState();
}

class _HotelSearchViewState extends State<HotelSearchView> {
  final List<Map<String, dynamic>> _hotels = [
    {
      'name': 'Grand Luxury Hotel',
      'rating': 5,
      'price': 299,
      'originalPrice': 399,
      'location': 'Downtown',
      'distance': '0.5 km from center',
      'amenities': ['WiFi', 'Pool', 'Spa', 'Restaurant', 'Gym'],
      'image': 'assets/images/hotel1.jpg',
      'reviews': 245,
      'reviewScore': 4.8,
      'description': 'Luxury hotel in the heart of the city',
    },
    {
      'name': 'Business Plaza Hotel',
      'rating': 4,
      'price': 189,
      'originalPrice': 229,
      'location': 'Business District',
      'distance': '1.2 km from center',
      'amenities': ['WiFi', 'Business Center', 'Restaurant', 'Parking'],
      'image': 'assets/images/hotel2.jpg',
      'reviews': 156,
      'reviewScore': 4.5,
      'description': 'Perfect for business travelers',
    },
    {
      'name': 'Comfort Inn & Suites',
      'rating': 3,
      'price': 129,
      'originalPrice': 159,
      'location': 'Airport Area',
      'distance': '15 km from center',
      'amenities': ['WiFi', 'Breakfast', 'Shuttle', 'Parking'],
      'image': 'assets/images/hotel3.jpg',
      'reviews': 89,
      'reviewScore': 4.2,
      'description': 'Comfortable stay near airport',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Hotel Search Results',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(
              Icons.filter_list,
              color: AppColors.primaryColor,
            ),
          ),
          IconButton(
            onPressed: _showMapView,
            icon: const Icon(
              Icons.map,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildResultsHeader(),
          const Divider(height: 1),
          Expanded(
            child: _buildHotelsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      color: AppColors.dividerColor.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_hotels.length} hotels found',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                'Sort by: ',
                style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
              ),
              GestureDetector(
                onTap: _showSortOptions,
                child: Text(
                  'Price',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsList() {
    if (_hotels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel,
              size: 64,
              color: AppColors.fadedTextColor,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No hotels found',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: _hotels.length,
      itemBuilder: (context, index) {
        final hotel = _hotels[index];
        return _buildHotelCard(hotel);
      },
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadiusMedium),
              ),
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.hotel,
                    size: 48,
                    color: AppColors.primaryColor,
                  ),
                ),
                if (hotel['originalPrice'] > hotel['price'])
                  Positioned(
                    top: AppTheme.spacingSmall,
                    left: AppTheme.spacingSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        '${((hotel['originalPrice'] - hotel['price']) / hotel['originalPrice'] * 100).round()}% OFF',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.backgroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: AppTheme.spacingSmall,
                  right: AppTheme.spacingSmall,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXSmall),
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: AppColors.primaryColor,
                      size: 20,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel['name'],
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXSmall),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < hotel['rating'] ? Icons.star : Icons.star_border,
                                color: AppColors.warningColor,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${hotel['price']}',
                          style: AppTheme.titleLarge.copyWith(
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
                        if (hotel['originalPrice'] > hotel['price'])
                          Text(
                            '\$${hotel['originalPrice']}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.errorColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.fadedTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      '${hotel['location']} • ${hotel['distance']}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        hotel['reviewScore'].toString(),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.backgroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      'Excellent',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      '(${hotel['reviews']} reviews)',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                Text(
                  hotel['description'],
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textColor,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                // Amenities
                Wrap(
                  spacing: AppTheme.spacingXSmall,
                  runSpacing: AppTheme.spacingXSmall,
                  children: (hotel['amenities'] as List<String>).take(4).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        amenity,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showHotelDetails(hotel),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bookHotel(hotel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          ),
                        ),
                        child: Text(
                          'Book Now',
                          style: AppTheme.buttonText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hotel Filters',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'Price range, star rating, amenities, and location filters will be implemented here',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Hotels By',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ListTile(
              title: const Text('Price: Low to High'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Price: High to Low'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Star Rating'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Guest Rating'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapView() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map View'),
        content: const Text('Hotel map view will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHotelDetails(Map<String, dynamic> hotel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hotel['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating: ${hotel['rating']} stars'),
            Text('Price: \$${hotel['price']} per night'),
            Text('Location: ${hotel['location']}'),
            Text('Distance: ${hotel['distance']}'),
            Text('Review Score: ${hotel['reviewScore']} (${hotel['reviews']} reviews)'),
            const SizedBox(height: AppTheme.spacingSmall),
            Text('Amenities: ${(hotel['amenities'] as List<String>).join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bookHotel(hotel);
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  void _bookHotel(Map<String, dynamic> hotel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Hotel'),
        content: Text('Booking ${hotel['name']} for \$${hotel['price']} per night'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to booking confirmation
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}
