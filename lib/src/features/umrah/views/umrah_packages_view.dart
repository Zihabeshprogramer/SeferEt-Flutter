import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../models/package.dart';
import '../../../providers/package_provider.dart';

class UmrahPackagesView extends ConsumerStatefulWidget {
  const UmrahPackagesView({super.key});

  @override
  ConsumerState<UmrahPackagesView> createState() => _UmrahPackagesViewState();
}

class _UmrahPackagesViewState extends ConsumerState<UmrahPackagesView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Load packages when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(packageListProvider.notifier).loadPackages(refresh: true);
    });
    
    // Set up pagination listener
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(packageListProvider.notifier).loadMorePackages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final packageState = ref.watch(packageListProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Umrah Packages',
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
            onPressed: () {
              ref.read(packageListProvider.notifier).loadPackages(refresh: true);
            },
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(packageListProvider.notifier).loadPackages(refresh: true);
        },
        child: Column(
          children: [
            _buildResultsHeader(packageState),
            const Divider(height: 1),
            Expanded(
              child: _buildPackagesList(packageState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(PackageListState state) {
    final totalCount = state.pagination?.total ?? state.packages.length;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      color: AppColors.dividerColor.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state.isLoading && state.packages.isEmpty
                ? 'Loading packages...'
                : '$totalCount packages found',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                'Sort by: ',
                style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
              ),
              GestureDetector(
                onTap: _showSortDialog,
                child: Text(
                  _getSortLabel(ref.read(packageListProvider.notifier).currentFilters.sortBy),
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
  
  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price':
        return 'Price';
      case 'rating':
        return 'Rating';
      case 'duration':
        return 'Duration';
      case 'popularity':
        return 'Popularity';
      default:
        return 'Newest';
    }
  }

  Widget _buildPackagesList(PackageListState state) {
    if (state.hasError && state.packages.isEmpty) {
      return Center(
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
              'Error loading packages',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              state.errorMessage,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton(
              onPressed: () {
                ref.read(packageListProvider.notifier).loadPackages(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.packages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spacingMedium),
            Text('Loading packages...'),
          ],
        ),
      );
    }

    if (state.packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mosque,
              size: 64,
              color: AppColors.fadedTextColor,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No packages found',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Try adjusting your filters',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: state.packages.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.packages.length) {
          // Loading indicator for pagination
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final package = state.packages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(Package package) {
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
          // Package Image
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadiusMedium),
              ),
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            child: Stack(
              children: [
                if (package.mainImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: package.mainImageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.mosque,
                          size: 48,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Icon(
                      Icons.mosque,
                      size: 48,
                      color: AppColors.primaryColor,
                    ),
                  ),
                if (package.hasDiscount)
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
                        '${package.discountPercentage.round()}% OFF',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.backgroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                // Featured badge
                if (package.isFeatured)
                  Positioned(
                    top: AppTheme.spacingSmall,
                    right: AppTheme.spacingSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        'FEATURED',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.backgroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Package Details
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        package.name,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${package.currency} ${package.displayPrice.toStringAsFixed(0)}',
                          style: AppTheme.titleLarge.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (package.hasDiscount)
                          Text(
                            '${package.currency} ${package.basePrice.toStringAsFixed(0)}',
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
                
                Text(
                  package.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.fadedTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.fadedTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      package.durationFormatted,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Icon(
                      Icons.category,
                      size: 16,
                      color: AppColors.fadedTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Expanded(
                      child: Text(
                        package.typeLabel,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.fadedTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      package.rating.average.toStringAsFixed(1),
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      '(${package.rating.count} reviews)',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                    ),
                    const Spacer(),
                    if (package.freeCancellation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Text(
                          'FREE CANCEL',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.successColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                // Highlights/Features
                if (package.highlights.isNotEmpty)
                  Wrap(
                    spacing: AppTheme.spacingXSmall,
                    runSpacing: AppTheme.spacingXSmall,
                    children: package.highlights.map((highlight) {
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
                          highlight,
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
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToPackageDetails(package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPackageDetails(Package package) {
    Navigator.pushNamed(
      context,
      '/tour-details',
      arguments: {
        'id': package.id,
        'slug': package.slug,
        'name': package.name,
        'description': package.description,
        'price': package.displayPrice,
        'rating': package.rating.average,
        'category': package.typeLabel,
        'images': package.images,
      },
    );
  }
  
  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort Packages',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ..._buildSortOptions(),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildSortOptions() {
    final sortOptions = [
      {'key': 'created_at', 'label': 'Newest', 'icon': Icons.access_time},
      {'key': 'price', 'label': 'Price', 'icon': Icons.attach_money},
      {'key': 'rating', 'label': 'Rating', 'icon': Icons.star},
      {'key': 'duration', 'label': 'Duration', 'icon': Icons.schedule},
      {'key': 'popularity', 'label': 'Popularity', 'icon': Icons.trending_up},
    ];
    
    final currentSort = ref.read(packageListProvider.notifier).currentFilters.sortBy;
    
    return sortOptions.map((option) {
      final isSelected = currentSort == option['key'];
      return ListTile(
        leading: Icon(
          option['icon'] as IconData,
          color: isSelected ? AppColors.primaryColor : AppColors.fadedTextColor,
        ),
        title: Text(
          option['label'] as String,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? AppColors.primaryColor : AppColors.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected 
            ? const Icon(Icons.check, color: AppColors.primaryColor)
            : null,
        onTap: () {
          Navigator.pop(context);
          final currentFilters = ref.read(packageListProvider.notifier).currentFilters;
          final newFilters = currentFilters.copyWith(sortBy: option['key'] as String);
          ref.read(packageListProvider.notifier).applyFilters(newFilters);
        },
      );
    }).toList();
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              children: [
                Text(
                  'Filter Packages',
                  style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: _buildFilterContent(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFilterContent() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesAsync = ref.watch(packageCategoriesProvider);
        
        return categoriesAsync.when(
          data: (categories) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Package Types',
                style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Wrap(
                spacing: AppTheme.spacingSmall,
                runSpacing: AppTheme.spacingSmall,
                children: categories.types.map((type) {
                  return FilterChip(
                    label: Text('${type.label} (${type.count})'),
                    selected: false, // TODO: Implement filter state
                    onSelected: (selected) {
                      // TODO: Apply type filter
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(packageListProvider.notifier).clearFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dividerColor,
                        foregroundColor: AppColors.textColor,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Apply selected filters
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Text(
            'Failed to load filter options',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.errorColor,
            ),
          ),
        );
      },
    );
  }

}
