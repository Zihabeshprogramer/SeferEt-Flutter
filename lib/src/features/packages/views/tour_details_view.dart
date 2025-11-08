import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../models/package.dart';
import '../../../providers/package_provider.dart';

class TourDetailsView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? destination;
  
  const TourDetailsView({super.key, this.destination});

  @override
  ConsumerState<TourDetailsView> createState() => _TourDetailsViewState();
}

class _TourDetailsViewState extends ConsumerState<TourDetailsView> {
  bool _isFavorite = false;
  dynamic _packageId;
  
  @override
  void initState() {
    super.initState();
    _packageId = widget.destination?['id'] ?? widget.destination?['slug'];
  }
  
  @override
  Widget build(BuildContext context) {
    // If we have a package ID, use the API to fetch details
    if (_packageId != null) {
      return _buildWithPackageProvider();
    }
    
    // Fallback for legacy usage
    final destination = widget.destination ?? {
      'name': 'Beautiful Destination',
      'description': 'Explore this amazing place with stunning views and rich culture.',
      'price': 299.0,
      'rating': 4.8,
      'category': 'Adventure',
    };

    return _buildLegacyView(destination);
  }
  
  Widget _buildWithPackageProvider() {
    final packageAsync = ref.watch(packageDetailsProvider(_packageId));
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: packageAsync.when(
        data: (package) => _buildPackageView(package),
        loading: () => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppTheme.spacingMedium),
                Text('Loading package details...'),
              ],
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Failed to load package details',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  error.toString(),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.fadedTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(packageDetailsProvider(_packageId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPackageView(Package package) {
    return CustomScrollView(
      slivers: [
        _buildPackageSliverAppBar(package),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPackageTitleSection(package),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildPackageDescriptionSection(package),
                if (package.inclusions != null && package.inclusions!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildInclusionsSection(package),
                ],
                if (package.activities != null && package.activities!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildActivitiesSection(package),
                ],
                if (package.hotels != null && package.hotels!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildHotelsSection(package),
                ],
                const SizedBox(height: AppTheme.spacingLarge),
                _buildPackageBookingSection(package),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegacyView(Map<String, dynamic> destination) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(destination),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(destination),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildDescriptionSection(destination),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildFeaturesSection(),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildBookingSection(destination),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> destination) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? AppColors.errorColor : AppColors.textTitleColor,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
          child: Icon(
            Icons.landscape,
            size: 100,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Map<String, dynamic> destination) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination['name'],
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Text(
                    destination['rating'].toString(),
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSmall,
                      vertical: AppTheme.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Text(
                      destination['category'] ?? 'Category',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          '\$${destination['price']}',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> destination) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          destination['description'],
          style: AppTheme.bodyMedium.copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'icon': Icons.wifi, 'title': 'Free WiFi'},
      {'icon': Icons.local_parking, 'title': 'Parking'},
      {'icon': Icons.pool, 'title': 'Swimming Pool'},
      {'icon': Icons.restaurant, 'title': 'Restaurant'},
      {'icon': Icons.fitness_center, 'title': 'Gym'},
      {'icon': Icons.spa, 'title': 'Spa'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: AppTheme.spacingSmall,
            mainAxisSpacing: AppTheme.spacingSmall,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Text(
                    feature['title'] as String,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingSection(Map<String, dynamic> destination) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${destination['price']}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showBookingDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
              child: Text(
                'Book Now',
                style: AppTheme.buttonText.copyWith(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSliverAppBar(Package package) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? AppColors.errorColor : AppColors.textTitleColor,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: package.images.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.landscape,
                size: 100,
                color: AppColors.primaryColor,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.landscape,
                size: 100,
                color: AppColors.primaryColor,
              ),
            ),
      ),
    );
  }

  Widget _buildPackageTitleSection(Package package) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                package.name,
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Text(
                    package.rating.average.toStringAsFixed(1),
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSmall,
                      vertical: AppTheme.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Text(
                      package.type.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (package.pricing?.basePrice != null)
          Text(
            '\$${package.pricing!.basePrice.toStringAsFixed(0)}',
            style: AppTheme.titleLarge.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildPackageDescriptionSection(Package package) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          package.description,
          style: AppTheme.bodyMedium.copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildInclusionsSection(Package package) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inclusions',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        ...package.inclusions!.map((inclusion) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.successColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Text(
                  inclusion,
                  style: AppTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActivitiesSection(Package package) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activities',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        ...package.activities!.map((activity) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityName,
                  style: AppTheme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXSmall),
                Text(
                  activity.description,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildHotelsSection(Package package) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotels',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        ...package.hotels!.map((hotel) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hotel.name,
                        style: AppTheme.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hotel.rating != null)
                      Row(
                        children: List.generate(
                          hotel.rating!.toInt(),
                          (index) => const Icon(
                            Icons.star,
                            color: AppColors.warningColor,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                if (hotel.location != null) ...[
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Text(
                    hotel.location!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.fadedTextColor,
                    ),
                  ),
                ],
                if (hotel.description != null) ...[
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Text(
                    hotel.description!,
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPackageBookingSection(Package package) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (package.pricing?.basePrice != null)
                Text(
                  '\$${package.pricing!.basePrice.toStringAsFixed(0)}',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showBookingDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
              child: Text(
                'Book Now',
                style: AppTheme.buttonText.copyWith(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmation'),
        content: const Text('Would you like to proceed with this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking confirmed! Check your email for details.'),
                  backgroundColor: AppColors.successColor,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
