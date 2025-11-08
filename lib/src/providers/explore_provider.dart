import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seferet_flutter/src/models/explore_models.dart';
import 'package:seferet_flutter/src/providers/package_provider.dart';

/// State for the Explore View
class ExploreState {
  final ProductType selectedType;
  final List<ExploreItem> items;
  final List<ExploreItem> featuredItems;
  final List<ExploreItem> recommendedItems;
  final bool isLoading;
  final String? errorMessage;
  final ExploreFilters filters;
  final String sortBy;

  const ExploreState({
    this.selectedType = ProductType.packages,
    this.items = const [],
    this.featuredItems = const [],
    this.recommendedItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filters = const ExploreFilters(),
    this.sortBy = 'featured',
  });

  ExploreState copyWith({
    ProductType? selectedType,
    List<ExploreItem>? items,
    List<ExploreItem>? featuredItems,
    List<ExploreItem>? recommendedItems,
    bool? isLoading,
    String? errorMessage,
    ExploreFilters? filters,
    String? sortBy,
  }) {
    return ExploreState(
      selectedType: selectedType ?? this.selectedType,
      items: items ?? this.items,
      featuredItems: featuredItems ?? this.featuredItems,
      recommendedItems: recommendedItems ?? this.recommendedItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<ExploreItem> get filteredItems {
    return _applyFiltersAndSort(items);
  }

  List<ExploreItem> _applyFiltersAndSort(List<ExploreItem> source) {
    var result = List<ExploreItem>.from(source);

    // Apply price filter
    if (filters.minPrice != null || filters.maxPrice != null) {
      result = result.where((item) {
        final price = item.price;
        if (price == null) return false;
        if (filters.minPrice != null && price < filters.minPrice!) return false;
        if (filters.maxPrice != null && price > filters.maxPrice!) return false;
        return true;
      }).toList();
    }

    // Apply rating filter
    if (filters.minRating != null) {
      result = result.where((item) {
        final rating = item.rating;
        return rating != null && rating >= filters.minRating!;
      }).toList();
    }

    // Apply location filter
    if (filters.location != null && filters.location!.isNotEmpty) {
      result = result.where((item) {
        final location = item.location?.toLowerCase() ?? '';
        return location.contains(filters.location!.toLowerCase());
      }).toList();
    }

    // Apply featured filter
    if (filters.isFeatured != null) {
      result = result.where((item) => item.isFeatured == filters.isFeatured).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'price_asc':
        result.sort((a, b) {
          final priceA = a.price ?? double.infinity;
          final priceB = b.price ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_desc':
        result.sort((a, b) {
          final priceA = a.price ?? 0;
          final priceB = b.price ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'rating':
        result.sort((a, b) {
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'featured':
      default:
        result.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return 0;
        });
        break;
    }

    return result;
  }
}

/// Explore View Notifier
class ExploreNotifier extends StateNotifier<ExploreState> {
  final Ref ref;

  ExploreNotifier(this.ref) : super(const ExploreState());

  /// Sync data from package provider without triggering loading
  void syncFromPackageProvider() {
    final packageState = ref.read(packageListProvider);
    
    // Convert packages to ExploreItems
    final items = packageState.packages
        .map((pkg) => ExploreItem.fromPackage(pkg))
        .toList();

    final featured = items.where((item) => item.isFeatured).take(5).toList();

    state = state.copyWith(
      items: items,
      featuredItems: featured,
      isLoading: packageState.isLoading,
      errorMessage: packageState.hasError ? packageState.errorMessage : null,
    );
  }


  /// Load recommended items (mix of all types)
  Future<void> loadRecommended() async {
    try {
      // Get packages
      final packageState = ref.read(packageListProvider);
      final packageItems = packageState.packages
          .where((pkg) => pkg.isFeatured || pkg.rating.average >= 4.0)
          .take(3)
          .map((pkg) => ExploreItem.fromPackage(pkg))
          .toList();

      // Mix recommendations
      final recommended = [...packageItems];
      
      state = state.copyWith(recommendedItems: recommended);
    } catch (e) {
      // Silent fail for recommendations
    }
  }

  /// Switch product type
  void switchType(ProductType type) {
    if (state.selectedType != type) {
      state = state.copyWith(
        selectedType: type,
        items: [],
        featuredItems: [],
      );
    }
  }

  /// Update filters
  void updateFilters(ExploreFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Clear filters
  void clearFilters() {
    state = state.copyWith(
      filters: ExploreFilters(),
    );
  }

  /// Update sort order
  void updateSort(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// Refresh current data
  Future<void> refresh() async {
    syncFromPackageProvider();
    await loadRecommended();
  }
}

/// Provider for Explore View state
final exploreProvider = StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  return ExploreNotifier(ref);
});
