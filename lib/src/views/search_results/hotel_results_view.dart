import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class HotelResultsView extends StatefulWidget {
  final String destination;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;
  final int rooms;
  final String starRating;

  const HotelResultsView({
    super.key,
    required this.destination,
    this.checkIn,
    this.checkOut,
    required this.guests,
    required this.rooms,
    required this.starRating,
  });

  @override
  State<HotelResultsView> createState() => _HotelResultsViewState();
}

class _HotelResultsViewState extends State<HotelResultsView> {
  String _sortBy = 'price';
  
  // Mock hotel data
  final List<Map<String, dynamic>> _hotels = [
    {
      'name': 'Sheraton Addis',
      'star_rating': 5,
      'rating': 4.5,
      'review_count': 1250,
      'image': '🏨',
      'amenities': ['WiFi', 'Pool', 'Gym', 'Spa'],
      'price_per_night': 180.0,
      'total_price': 720.0,
      'currency': 'USD',
      'location': '2.1 km from city center',
    },
    {
      'name': 'Radisson Blu Hotel',
      'star_rating': 4,
      'rating': 4.3,
      'review_count': 890,
      'image': '🏨',
      'amenities': ['WiFi', 'Restaurant', 'Gym', 'Business Center'],
      'price_per_night': 120.0,
      'total_price': 480.0,
      'currency': 'USD',
      'location': '1.5 km from city center',
    },
    {
      'name': 'Hyatt Regency',
      'star_rating': 5,
      'rating': 4.6,
      'review_count': 2100,
      'image': '🏨',
      'amenities': ['WiFi', 'Pool', 'Multiple Restaurants', 'Concierge'],
      'price_per_night': 220.0,
      'total_price': 880.0,
      'currency': 'USD',
      'location': '0.8 km from city center',
    },
    {
      'name': 'Capital Hotel & Spa',
      'star_rating': 4,
      'rating': 4.2,
      'review_count': 650,
      'image': '🏨',
      'amenities': ['WiFi', 'Spa', 'Restaurant', 'Room Service'],
      'price_per_night': 95.0,
      'total_price': 380.0,
      'currency': 'USD',
      'location': '3.2 km from city center',
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
          'Hotel Results',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: AppColors.primaryColor),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              PopupMenuItem(value: 'rating', child: Text('Sort by Rating')),
              PopupMenuItem(value: 'distance', child: Text('Sort by Distance')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSummary(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: _hotels.length,
              itemBuilder: (context, index) => _buildHotelCard(_hotels[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
    final checkInText = widget.checkIn != null
        ? '${widget.checkIn!.day}/${widget.checkIn!.month}'
        : '';
    final checkOutText = widget.checkOut != null
        ? '${widget.checkOut!.day}/${widget.checkOut!.month}'
        : '';
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: AppColors.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.destination,
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$checkInText - $checkOutText • ${widget.guests} guest${widget.guests > 1 ? 's' : ''} • ${widget.rooms} room${widget.rooms > 1 ? 's' : ''} • ${widget.starRating}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel image placeholder
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                topRight: Radius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
            child: Center(
              child: Text(
                hotel['image'],
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel['name'],
                            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              ...List.generate(
                                hotel['star_rating'],
                                (index) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppColors.warningColor,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSmall),
                              Text(
                                '${hotel['rating']} (${hotel['review_count']} reviews)',
                                style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${hotel['price_per_night'].toStringAsFixed(0)}',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'per night',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  hotel['location'],
                  style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Wrap(
                  spacing: AppTheme.spacingSmall,
                  runSpacing: 4,
                  children: hotel['amenities']
                      .map<Widget>((amenity) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              amenity,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          ),
                        ),
                        onPressed: () => _viewHotelDetails(hotel),
                        child: Text(
                          'View Details',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          ),
                        ),
                        onPressed: () => _bookHotel(hotel),
                        child: Text(
                          'Book Now',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.backgroundColor,
                            fontWeight: FontWeight.w600,
                          ),
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

  void _viewHotelDetails(Map<String, dynamic> hotel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${hotel['name']}'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _bookHotel(Map<String, dynamic> hotel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${hotel['name']} for \$${hotel['total_price']}'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }
}
