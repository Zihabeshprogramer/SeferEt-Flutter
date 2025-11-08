import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../models/hotel_models.dart';
import '../../../providers/hotel_provider.dart';

class HotelDetailPage extends StatefulWidget {
  final String hotelId;
  final Hotel? hotel; // Optional: pass hotel if already loaded

  const HotelDetailPage({
    super.key,
    required this.hotelId,
    this.hotel,
  });

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.hotel == null) {
      // Load hotel details if not provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HotelProvider>().getHotelDetails(widget.hotelId);
      });
    } else {
      // Use provided hotel
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<HotelProvider>();
        provider.clearDetails();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final hotel = widget.hotel ?? provider.selectedHotel;

          if (provider.isLoadingDetails && widget.hotel == null) {
            return _buildLoadingState();
          }

          if (provider.detailState == HotelViewState.error) {
            return _buildErrorState(provider.detailError ?? 'Failed to load hotel');
          }

          if (hotel == null) {
            return _buildErrorState('Hotel not found');
          }

          return _buildHotelDetails(hotel);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
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
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelDetails(Hotel hotel) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(hotel),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHotelHeader(hotel),
              const Divider(height: 1),
              _buildQuickInfo(hotel),
              const Divider(height: 1),
              _buildHotelInfo(hotel),
              const Divider(height: 1),
              _buildAmenities(hotel),
              const Divider(height: 1),
              _buildLocationInfo(hotel),
              const Divider(height: 1),
              _buildContactInfo(hotel),
              if (hotel.offers != null && hotel.offers!.isNotEmpty) ...[
                const Divider(height: 1),
                _buildOffers(hotel),
              ],
              const SizedBox(height: AppTheme.spacingXLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(Hotel hotel) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hotel.imageUrl != null)
              Image.network(
                hotel.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              )
            else
              _buildPlaceholderImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            if (hotel.isAmadeus)
              Positioned(
                top: 60,
                right: 16,
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
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Powered by Amadeus',
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.1),
      child: const Center(
        child: Icon(
          Icons.hotel,
          size: 80,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildHotelHeader(Hotel hotel) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hotel.name,
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hotel.lowestPrice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${hotel.lowestPrice!.toStringAsFixed(0)}',
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
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < hotel.rating ? Icons.star : Icons.star_border,
                color: AppColors.warningColor,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppColors.fadedTextColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hotel.displayLocation,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.fadedTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (hotel.distance != null) ...[
            const SizedBox(height: 4),
            Text(
              hotel.distanceText,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
          ],
          if (hotel.guestRating != null) ...[
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
                    hotel.guestRating!.toStringAsFixed(1),
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  _getRatingText(hotel.guestRating!),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hotel.reviewCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${hotel.reviewCount} reviews)',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.fadedTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotelInfo(Hotel hotel) {
    if (hotel.description == null || hotel.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this hotel',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            hotel.description!,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(Hotel hotel) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              Icons.hotel,
              'Check-in',
              '2:00 PM',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: _buildInfoItem(
              Icons.logout,
              'Check-out',
              '12:00 PM',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: _buildInfoItem(
              Icons.star,
              'Rating',
              '${hotel.rating} Star',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(Hotel hotel) {
    if (hotel.amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Amenities',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 4,
            mainAxisSpacing: AppTheme.spacingSmall,
            crossAxisSpacing: AppTheme.spacingSmall,
            children: hotel.amenities.map((amenity) {
              final amenityData = _getAmenityIcon(amenity);
              return Row(
                children: [
                  Icon(
                    amenityData['icon'] as IconData,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      amenity,
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return {'icon': Icons.wifi, 'color': AppColors.primaryColor};
    } else if (lower.contains('pool') || lower.contains('swimming')) {
      return {'icon': Icons.pool, 'color': AppColors.primaryColor};
    } else if (lower.contains('parking')) {
      return {'icon': Icons.local_parking, 'color': AppColors.primaryColor};
    } else if (lower.contains('gym') || lower.contains('fitness')) {
      return {'icon': Icons.fitness_center, 'color': AppColors.primaryColor};
    } else if (lower.contains('restaurant') || lower.contains('dining')) {
      return {'icon': Icons.restaurant, 'color': AppColors.primaryColor};
    } else if (lower.contains('spa')) {
      return {'icon': Icons.spa, 'color': AppColors.primaryColor};
    } else if (lower.contains('bar')) {
      return {'icon': Icons.local_bar, 'color': AppColors.primaryColor};
    } else if (lower.contains('air') || lower.contains('ac')) {
      return {'icon': Icons.ac_unit, 'color': AppColors.primaryColor};
    } else if (lower.contains('tv')) {
      return {'icon': Icons.tv, 'color': AppColors.primaryColor};
    } else if (lower.contains('room service')) {
      return {'icon': Icons.room_service, 'color': AppColors.primaryColor};
    } else if (lower.contains('laundry')) {
      return {'icon': Icons.local_laundry_service, 'color': AppColors.primaryColor};
    } else if (lower.contains('elevator')) {
      return {'icon': Icons.elevator, 'color': AppColors.primaryColor};
    }
    return {'icon': Icons.check_circle, 'color': AppColors.successColor};
  }

  Widget _buildLocationInfo(Hotel hotel) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          if (hotel.address != null && hotel.address!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place, size: 18, color: AppColors.fadedTextColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hotel.address!,
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
          ],
          if (hotel.cityName != null) ...[
            Row(
              children: [
                const Icon(Icons.location_city, size: 18, color: AppColors.fadedTextColor),
                const SizedBox(width: 8),
                Text(
                  hotel.cityName!,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (hotel.distance != null) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 18, color: AppColors.fadedTextColor),
                const SizedBox(width: 8),
                Text(
                  hotel.distanceText,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(Hotel hotel) {
    // Only show if we have contact info (only available for local hotels)
    if (hotel.isAmadeus) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_page, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'For inquiries, please contact the hotel directly after booking.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.fadedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffers(Hotel hotel) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Rooms',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          ...hotel.offers!.map((offer) => _buildOfferCard(hotel, offer)).toList(),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Hotel hotel, HotelOffer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
      ),
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
                      offer.roomType,
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (offer.bedType != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        offer.bedType!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.fadedTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                offer.priceText,
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (offer.description != null) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              offer.description!,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textColor,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSmall),
          Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: 4,
            children: [
              if (offer.breakfastIncluded)
                _buildFeatureChip('Breakfast included', Icons.restaurant),
              if (offer.cancellable)
                _buildFeatureChip('Free cancellation', Icons.check_circle),
              _buildFeatureChip('${offer.guests} guest${offer.guests > 1 ? 's' : ''}', Icons.person),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/hotel-booking',
                  arguments: {
                    'hotel': hotel,
                    'offer': offer,
                  },
                );
              },
              child: const Text('Book This Room'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.successColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.successColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Average';
    return 'Fair';
  }
}
