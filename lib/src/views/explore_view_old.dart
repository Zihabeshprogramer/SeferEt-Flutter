import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/package.dart' hide Duration;
import '../providers/package_provider.dart';

class ExploreView extends ConsumerStatefulWidget {
  const ExploreView({super.key});

  @override
  ConsumerState<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends ConsumerState<ExploreView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // State variables
  bool _isLoading = true;
  bool _isInitialized = false;
  List<String> _categories = ['all'];
  String _selectedCategory = 'all';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    debugPrint('ExploreView: Starting initialization...');
    debugPrint('ExploreView: API Base URL: ${AppConstants.baseUrl}');
    debugPrint('ExploreView: Environment: ${AppConstants.isDevelopment ? "Development" : "Production"}');
    
    try {
      // Load categories first (non-critical)
      debugPrint('ExploreView: Loading categories...');
      await _loadCategories();
      debugPrint('ExploreView: Categories loaded successfully');
    } catch (e) {
      debugPrint('ExploreView: Categories failed to load: $e');
      // Continue even if categories fail
    }
    
    // Mark UI as initialized
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
      debugPrint('ExploreView: UI initialized and marked as ready');
    }
    
    // Trigger package loading
    debugPrint('ExploreView: Triggering package loading...');
    try {
      final filters = PackageFilters(
        type: _selectedCategory == 'all' ? null : _selectedCategory,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      await ref.read(packageListProvider.notifier).applyFilters(filters);
      debugPrint('ExploreView: Package loading completed successfully');
    } catch (e) {
      debugPrint('ExploreView: Package loading failed: $e');
      // Error will be handled by the provider state
    }
    
    debugPrint('ExploreView: Initialization complete');
  }


  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      debugPrint('ExploreView: Fetching categories from service...');
      // Use the package service directly to avoid AsyncValue complexity
      final packageService = ref.read(packageServiceProvider);
      final response = await packageService.getCategories();
      
      if (response.success && response.data != null && mounted) {
        debugPrint('ExploreView: Categories fetched successfully: ${response.data!.types.length} types');
        setState(() {
          _categories = ['all', ...response.data!.types.map((type) => type.key)];
          _isInitialized = true;
        });
      } else if (mounted) {
        debugPrint('ExploreView: Categories response failed or empty');
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('ExploreView: Categories loading error: $e');
      // If categories fail to load, still mark as initialized
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _refreshPackages() {
    final filters = PackageFilters(
      type: _selectedCategory == 'all' ? null : _selectedCategory,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    ref.read(packageListProvider.notifier).applyFilters(filters);
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    final filters = PackageFilters(
      type: category == 'all' ? null : category,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    ref.read(packageListProvider.notifier).applyFilters(filters);
  }

  void _onSortChanged(String value) {
    setState(() {
      if (value.contains('_')) {
        final parts = value.split('_');
        _sortBy = parts[0];
        _sortOrder = parts[1];
      } else {
        _sortBy = value;
        _sortOrder = 'desc';
      }
    });
    final filters = PackageFilters(
      type: _selectedCategory == 'all' ? null : _selectedCategory,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    ref.read(packageListProvider.notifier).applyFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Explore Packages',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              debugPrint('ExploreView: Manual refresh triggered');
              setState(() {
                _isLoading = true;
              });
              _initializeData();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.sort,
              color: AppColors.primaryColor,
            ),
            onSelected: _onSortChanged,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'created_at_desc',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'created_at_asc',
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: 'base_price_asc',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'base_price_desc',
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: 'bookings_count_desc',
                child: Text('Most Popular'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text('Loading explore data...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                if (_isInitialized) _buildCategoryTabs(),
                Expanded(
                  child: _buildPackageGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search packages...',
          hintStyle: AppTheme.bodyLarge.copyWith(
            color: AppColors.fadedTextColor,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.primaryColor,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.fadedTextColor,
                  ),
                )
              : null,
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() {}),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            // Navigate to search results or implement search functionality
            Navigator.pushNamed(context, '/search-results', arguments: {
              'query': value,
              'type': 'packages',
            });
          }
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return GestureDetector(
            onTap: () => _onCategoryChanged(category),
            child: Container(
              margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : AppColors.dividerColor,
                ),
              ),
              child: Center(
                child: Text(
                  category == 'all' ? 'All' : category.toUpperCase(),
                  style: AppTheme.labelLarge.copyWith(
                    color: isSelected ? AppColors.textTitleColor : AppColors.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageGrid() {
    try {
      final packageListState = ref.watch(packageListProvider);
      
      // Handle loading state
      if (packageListState.isLoading && packageListState.packages.isEmpty) {
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
      
      // Handle error state
      if (packageListState.hasError && packageListState.packages.isEmpty) {
        debugPrint('ExploreView: Package loading error: ${packageListState.errorMessage}');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.errorColor,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Text(
                'Failed to load packages',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppColors.errorColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                packageListState.errorMessage,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.fadedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
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
      
      // Handle empty state
      if (packageListState.packages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: AppColors.fadedTextColor,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Text(
                'No packages found',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppColors.fadedTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'Try adjusting your filters or check back later',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.fadedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      // Show packages with pull-to-refresh
      debugPrint('ExploreView: Package data loaded - ${packageListState.packages.length} packages');
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(packageListProvider.notifier).loadPackages(refresh: true);
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72, // Slightly taller to fix overflow
            crossAxisSpacing: AppTheme.spacingMedium,
            mainAxisSpacing: AppTheme.spacingMedium,
          ),
          itemCount: packageListState.packages.length + (packageListState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show load more indicator at the end if there are more pages
            if (index >= packageListState.packages.length) {
              if (!packageListState.isLoading) {
                // Trigger load more
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(packageListProvider.notifier).loadMorePackages();
                });
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final package = packageListState.packages[index];
            return _buildPackageCard(package);
          },
        ),
      );
    } catch (e) {
      debugPrint('ExploreView: Unexpected error in _buildPackageGrid: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppColors.errorColor),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'Something went wrong',
              style: AppTheme.headlineSmall.copyWith(color: AppColors.errorColor),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Error: $e',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.fadedTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _initializeData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }




  Widget _buildOriginalPackageGrid() {
    try {
      final packageListState = ref.watch(packageListProvider);
      
      // Show loading state
      if (packageListState.isLoading && packageListState.packages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'Loading packages...',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                'This may take a few moments',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.fadedTextColor,
                ),
              ),
            ],
          ),
        );
      }
    
    if (packageListState.packages.isEmpty && !packageListState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: AppColors.fadedTextColor,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No packages available',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              AppConstants.isDevelopment 
                  ? 'Make sure the Laravel backend is running on localhost:8000'
                  : 'Check your internet connection or try again',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (AppConstants.isDevelopment) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: AppColors.warningColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Development Mode',
                      style: AppTheme.titleSmall.copyWith(
                        color: AppColors.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'API URL: ${AppConstants.baseUrl}\n\nStart your Laravel backend:\nphp artisan serve',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.warningColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            if (packageListState.errorMessage.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                ),
                child: Text(
                  packageListState.errorMessage,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    debugPrint('ExploreView: Retry button pressed - attempting reload');
                    setState(() {
                      _isLoading = true;
                    });
                    _initializeData();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                OutlinedButton(
                  onPressed: () {
                    debugPrint('ExploreView: Direct refresh triggered');
                    try {
                      ref.read(packageListProvider.notifier).loadPackages(refresh: true);
                    } catch (e) {
                      debugPrint('ExploreView: Direct refresh failed: $e');
                    }
                  },
                  child: const Text('Refresh Data'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    if (packageListState.hasError) {
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
              'Failed to load packages',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              packageListState.errorMessage,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton(
              onPressed: _refreshPackages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
      return RefreshIndicator(
        onRefresh: () async {
          _refreshPackages();
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: AppTheme.spacingMedium,
            mainAxisSpacing: AppTheme.spacingMedium,
          ),
          itemCount: packageListState.packages.length + (packageListState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= packageListState.packages.length) {
              // Load more indicator
              if (!packageListState.isLoading) {
                // Trigger load more
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    ref.read(packageListProvider.notifier).loadMorePackages();
                  } catch (e) {
                    debugPrint('ExploreView: Load more failed: $e');
                  }
                });
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final package = packageListState.packages[index];
            return _buildPackageCard(package);
          },
        ),
      );
    } catch (e) {
      debugPrint('ExploreView: Package grid error: $e');
      // Fallback UI when provider fails completely
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
              'Failed to load packages',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Please check your internet connection',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton(
              onPressed: () {
                // Restart the initialization
                setState(() {
                  _isLoading = true;
                });
                _initializeData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPackageCard(Package package) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/tour-details',
          arguments: {'id': package.id, 'slug': package.slug},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackTransparent,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                    topRight: Radius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                        topRight: Radius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: package.mainImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: package.mainImageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              color: AppColors.primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: AppColors.primaryColor,
                              ),
                            ),
                    ),
                    Positioned(
                      top: AppTheme.spacingSmall,
                      right: AppTheme.spacingSmall,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXSmall),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          package.isFeatured ? Icons.star : Icons.favorite_border,
                          size: 16,
                          color: package.isFeatured ? AppColors.warningColor : AppColors.primaryColor,
                        ),
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
                            '${package.discountPercentage.toStringAsFixed(0)}% OFF',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textTitleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXSmall),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warningColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          package.rating.average.toStringAsFixed(1),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' (${package.rating.count})',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.fadedTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusXSmall),
                            ),
                            child: Text(
                              package.typeLabel,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (package.hasDiscount) ...[
                              Text(
                                '${package.currency} ${package.basePrice.toStringAsFixed(0)}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.fadedTextColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '${package.currency} ${package.displayPrice.toStringAsFixed(0)}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              Text(
                                package.currency,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.fadedTextColor,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                package.basePrice.toStringAsFixed(0),
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
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
                            package.durationFormatted,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textTitleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
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
}