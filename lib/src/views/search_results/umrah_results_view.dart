import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class UmrahResultsView extends StatefulWidget {
  final String departureCity;
  final DateTime? departureDate;
  final int durationDays;
  final String packageType;

  const UmrahResultsView({
    super.key,
    required this.departureCity,
    this.departureDate,
    required this.durationDays,
    required this.packageType,
  });

  @override
  State<UmrahResultsView> createState() => _UmrahResultsViewState();
}

class _UmrahResultsViewState extends State<UmrahResultsView> {
  String _sortBy = 'price';
  
  // Mock Umrah package data
  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Premium Umrah Package',
      'operator': 'Al-Hijaz Tours',
      'duration': 14,
      'hotels': {
        'makkah': 'Hilton Suites Makkah (5 nights)',
        'madinah': 'Madinah Hilton (3 nights)',
      },
      'flight': 'Saudi Airlines',
      'includes': ['Visa', 'Flight', 'Hotel', 'Transportation', 'Guide'],
      'price': 2800.0,
      'currency': 'USD',
      'rating': 4.8,
      'reviews': 324,
      'image': '🕋',
    },
    {
      'name': 'Standard Umrah Package',
      'operator': 'Makkah Travel Co.',
      'duration': 14,
      'hotels': {
        'makkah': 'Swissotel Makkah (5 nights)',
        'madinah': 'Shaza Al Madinah (3 nights)',
      },
      'flight': 'Emirates',
      'includes': ['Visa', 'Flight', 'Hotel', 'Transportation'],
      'price': 2200.0,
      'currency': 'USD',
      'rating': 4.5,
      'reviews': 198,
      'image': '🕋',
    },
    {
      'name': 'Economy Umrah Package',
      'operator': 'Haramain Tours',
      'duration': 10,
      'hotels': {
        'makkah': 'Hotel near Haram (4 nights)',
        'madinah': 'Budget Hotel (2 nights)',
      },
      'flight': 'Saudi Airlines',
      'includes': ['Visa', 'Flight', 'Hotel', 'Transportation'],
      'price': 1600.0,
      'currency': 'USD',
      'rating': 4.2,
      'reviews': 156,
      'image': '🕋',
    },
    {
      'name': 'Luxury Umrah Package',
      'operator': 'Elite Hajj & Umrah',
      'duration': 21,
      'hotels': {
        'makkah': 'Raffles Makkah Palace (8 nights)',
        'madinah': 'Oberoi Madinah (5 nights)',
      },
      'flight': 'Qatar Airways',
      'includes': ['Visa', 'Flight', '5* Hotels', 'Private Transportation', 'VIP Guide', 'Meals'],
      'price': 4500.0,
      'currency': 'USD',
      'rating': 4.9,
      'reviews': 87,
      'image': '🕋',
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
          'Umrah Packages',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: AppColors.primaryColor),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              PopupMenuItem(value: 'rating', child: Text('Sort by Rating')),
              PopupMenuItem(value: 'duration', child: Text('Sort by Duration')),
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
              itemCount: _packages.length,
              itemBuilder: (context, index) => _buildPackageCard(_packages[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
    final dateText = widget.departureDate != null
        ? '${widget.departureDate!.day}/${widget.departureDate!.month}/${widget.departureDate!.year}'
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
            'From ${widget.departureCity}',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$dateText • ${widget.durationDays} days • ${widget.packageType}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
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
          // Package header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.secondaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                topRight: Radius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
            child: Row(
              children: [
                Text(
                  package['image'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package['name'],
                        style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'by ${package['operator']}',
                        style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${package['price'].toStringAsFixed(0)}',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per person',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 4),
                    Text('${package['duration']} days', style: AppTheme.bodySmall),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Icon(Icons.flight, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 4),
                    Text(package['flight'], style: AppTheme.bodySmall),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.warningColor),
                        const SizedBox(width: 4),
                        Text(
                          '${package['rating']} (${package['reviews']})',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Accommodation:',
                  style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.primaryColor),
                        const SizedBox(width: 4),
                        Text('Makkah: ', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        Expanded(child: Text(package['hotels']['makkah'], style: AppTheme.bodySmall)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.secondaryColor),
                        const SizedBox(width: 4),
                        Text('Madinah: ', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        Expanded(child: Text(package['hotels']['madinah'], style: AppTheme.bodySmall)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Package Includes:',
                  style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Wrap(
                  spacing: AppTheme.spacingSmall,
                  runSpacing: 4,
                  children: package['includes']
                      .map<Widget>((include) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.successColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              include,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.successColor,
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
                        onPressed: () => _viewPackageDetails(package),
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
                        onPressed: () => _bookPackage(package),
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

  void _viewPackageDetails(Map<String, dynamic> package) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${package['name']}'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _bookPackage(Map<String, dynamic> package) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${package['name']} for \$${package['price']}'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }
}
