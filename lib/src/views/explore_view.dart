import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/explore_models.dart';
import '../providers/explore_provider.dart';
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
    
    // Initialize package provider and sync to explore provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load packages first
      await ref.read(packageListProvider.notifier).loadPackages();
      // Then sync and load recommendations
      if (mounted) {
        ref.read(exploreProvider.notifier).syncFromPackageProvider();
        await ref.read(exploreProvider.notifier).loadRecommended();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundColor.withOpacity(0),
      builder: (context) => _buildFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(exploreState),
            _buildCategorySelector(exploreState),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(packageListProvider.notifier).loadPackages(refresh: true);
                  ref.read(exploreProvider.notifier).syncFromPackageProvider();
                  await ref.read(exploreProvider.notifier).loadRecommended();
                },
                child: CustomScrollView(
                  slivers: [
                    // Featured section
                    if (exploreState.featuredItems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionHeader('Featured ${exploreState.selectedType.label}'),
                      ),
                      SliverToBoxAdapter(
                        child: _buildFeaturedCarousel(exploreState.featuredItems),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingMedium)),
                    ],

                    // All items section
                    SliverToBoxAdapter(
                      child: _buildSectionHeader('All ${exploreState.selectedType.label}'),
                    ),

                    _buildItemsGrid(exploreState),

                    // Recommended section
                    if (exploreState.recommendedItems.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader('Recommended for You')),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                                child: _buildListCard(exploreState.recommendedItems[index]),
                              );
                            },
                            childCount: exploreState.recommendedItems.length,
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterSheet,
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.tune, color: AppColors.textTitleColor),
        label: Text(
          'Filters',
          style: AppTheme.labelLarge.copyWith(color: AppColors.textTitleColor),
        ),
      ),
    );
  }

  Widget _buildHeader(ExploreState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore',
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: AppColors.primaryColor),
                onSelected: (value) {
                  ref.read(exploreProvider.notifier).updateSort(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'featured', child: Text('Featured')),
                  const PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                  const PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                  const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightgrayBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search destinations, hotels, flights...',
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppColors.fadedTextColor,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear, color: AppColors.fadedTextColor),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCategorySelector(ExploreState state) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ProductType.values.length,
        itemBuilder: (context, index) {
          final type = ProductType.values[index];
          final isSelected = type == state.selectedType;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 18,
                      color: isSelected ? AppColors.textTitleColor : type.accentColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      type.label,
                      style: AppTheme.labelLarge.copyWith(
                        color: isSelected ? AppColors.textTitleColor : AppColors.textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  _animationController.reset();
                  _animationController.forward();
                  ref.read(exploreProvider.notifier).switchType(type);
                },
                selectedColor: type.accentColor,
                backgroundColor: AppColors.lightgrayBackground,
                side: BorderSide(
                  color: isSelected ? type.accentColor : AppColors.dividerColor,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        AppTheme.spacingLarge,
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
      ),
      child: Text(
        title,
        style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFeaturedCarousel(List<ExploreItem> items) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
            child: SizedBox(
              width: 260,
              child: _buildProductCard(items[index], featured: true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(ExploreState state) {
    if (state.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                state.errorMessage!,
                style: AppTheme.bodyMedium.copyWith(color: AppColors.fadedTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(packageListProvider.notifier).loadPackages(refresh: true);
                  ref.read(exploreProvider.notifier).syncFromPackageProvider();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final items = state.filteredItems;

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: AppColors.fadedTextColor),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'No ${state.selectedType.label.toLowerCase()} found',
                style: AppTheme.titleMedium.copyWith(color: AppColors.fadedTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: AppTheme.spacingMedium,
          mainAxisSpacing: AppTheme.spacingMedium,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildProductCard(items[index]),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(ExploreItem item, {bool featured = false}) {
    return GestureDetector(
      onTap: () => _handleCardTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackTransparent.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: featured ? 4 : 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                      topRight: Radius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: _buildImage(item),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                          topRight: Radius.circular(AppTheme.borderRadiusMedium),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.backgroundColor.withOpacity(0),
                            AppColors.blackTransparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Product type badge
                  Positioned(
                    top: AppTheme.spacingSmall,
                    left: AppTheme.spacingSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: item.type.accentColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.type.icon, size: 12, color: AppColors.textTitleColor),
                          const SizedBox(width: 4),
                          Text(
                            item.type.singular,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textTitleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Featured/Discount badge
                  if (item.hasDiscount)
                    Positioned(
                      top: AppTheme.spacingSmall,
                      right: AppTheme.spacingSmall,
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
                          '${item.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textTitleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                  else if (item.isFeatured)
                    Positioned(
                      top: AppTheme.spacingSmall,
                      right: AppTheme.spacingSmall,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXSmall),
                        decoration: const BoxDecoration(
                          color: AppColors.warningColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.textTitleColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content section
            Expanded(
              flex: featured ? 3 : 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: featured ? null : 13,
                      ),
                      maxLines: featured ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (featured) const SizedBox(height: 4) else const SizedBox(height: 2),
                    if (item.subtitle != null && featured)
                      Text(
                        item.subtitle!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.fadedTextColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (item.location != null && featured)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 10,
                              color: AppColors.fadedTextColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.location!,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.fadedTextColor,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (item.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.warningColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            if (item.reviewCount != null && featured)
                              Text(
                                ' (${item.reviewCount})',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.fadedTextColor,
                                  fontSize: 10,
                                ),
                              ),
                            const Spacer(),
                            if (item.duration != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusXSmall),
                                ),
                                child: Text(
                                  item.duration!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.hasDiscount && item.originalPrice != null) ...[
                          Text(
                            item.originalPriceDisplay,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.fadedTextColor,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            item.priceDisplay,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: featured ? null : 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildImage(ExploreItem item) {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primaryColor.withOpacity(0.1),
        child: Icon(
          item.type.icon,
          size: 48,
          color: AppColors.primaryColor.withOpacity(0.3),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.primaryColor.withOpacity(0.1),
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.primaryColor.withOpacity(0.1),
        child: Icon(
          item.type.icon,
          size: 48,
          color: AppColors.primaryColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    final exploreState = ref.watch(exploreProvider);
    final filters = exploreState.filters;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusLarge),
          topRight: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  ref.read(exploreProvider.notifier).clearFilters();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Price range
          Text('Price Range', style: AppTheme.titleSmall),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),

          // Rating filter
          Text('Minimum Rating', style: AppTheme.titleSmall),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.warningColor),
                      Text(' $rating+'),
                    ],
                  ),
                  selected: filters.minRating == rating.toDouble(),
                  onSelected: (selected) {
                    ref.read(exploreProvider.notifier).updateFilters(
                      filters.copyWith(minRating: selected ? rating.toDouble() : null),
                    );
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.spacingLarge),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(ExploreItem item) {
    return GestureDetector(
      onTap: () => _handleCardTap(item),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackTransparent.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                bottomLeft: Radius.circular(AppTheme.borderRadiusMedium),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: _buildImage(item),
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppColors.fadedTextColor,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  item.location!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.fadedTextColor,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.warningColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.rating!.toStringAsFixed(1),
                                style: AppTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          item.priceDisplay,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
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

  void _handleCardTap(ExploreItem item) {
    switch (item.type) {
      case ProductType.packages:
        Navigator.pushNamed(
          context,
          '/tour-details',
          arguments: {
            'id': int.parse(item.id),
            'slug': item.metadata?['slug'],
          },
        );
        break;
      case ProductType.hotels:
        // Navigate to hotel details
        // You'll need to implement hotel detail page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hotel details coming soon')),
        );
        break;
      case ProductType.flights:
        // Navigate to flight details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight details coming soon')),
        );
        break;
    }
  }
}
