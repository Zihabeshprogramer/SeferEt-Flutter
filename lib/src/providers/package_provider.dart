import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package.dart';
import '../services/package_service.dart';

/// Package service provider
final packageServiceProvider = Provider<PackageService>((ref) {
  return PackageService();
});

/// Package list state
class PackageListState {
  final List<Package> packages;
  final Pagination? pagination;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final bool hasMore;

  PackageListState({
    this.packages = const [],
    this.pagination,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.hasMore = true,
  });

  PackageListState copyWith({
    List<Package>? packages,
    Pagination? pagination,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
  }) {
    return PackageListState(
      packages: packages ?? this.packages,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Package filters
class PackageFilters {
  final String? type;
  final double? minPrice;
  final double? maxPrice;
  final int? duration;
  final List<String> destinations;
  final List<String> features;
  final String sortBy;
  final String sortOrder;

  PackageFilters({
    this.type,
    this.minPrice,
    this.maxPrice,
    this.duration,
    this.destinations = const [],
    this.features = const [],
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  PackageFilters copyWith({
    String? type,
    double? minPrice,
    double? maxPrice,
    int? duration,
    List<String>? destinations,
    List<String>? features,
    String? sortBy,
    String? sortOrder,
  }) {
    return PackageFilters(
      type: type ?? this.type,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      duration: duration ?? this.duration,
      destinations: destinations ?? this.destinations,
      features: features ?? this.features,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (type != null) 'type': type,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (duration != null) 'duration': duration,
      if (destinations.isNotEmpty) 'destinations': destinations,
      if (features.isNotEmpty) 'features': features,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }
}

/// Package list notifier
class PackageListNotifier extends StateNotifier<PackageListState> {
  final PackageService _packageService;
  PackageFilters _currentFilters = PackageFilters();
  int _currentPage = 1;
  static const int _pageSize = 20;

  PackageListNotifier(this._packageService) : super(PackageListState());

  /// Load packages with current filters
  Future<void> loadPackages({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = state.copyWith(packages: [], hasMore: true, hasError: false);
    }

    if (state.isLoading || (!state.hasMore && !refresh)) return;

    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final response = await _packageService.getPackages(
        page: _currentPage,
        perPage: _pageSize,
        type: _currentFilters.type,
        minPrice: _currentFilters.minPrice,
        maxPrice: _currentFilters.maxPrice,
        duration: _currentFilters.duration,
        destinations: _currentFilters.destinations.isNotEmpty ? _currentFilters.destinations : null,
        features: _currentFilters.features.isNotEmpty ? _currentFilters.features : null,
        sortBy: _currentFilters.sortBy,
        sortOrder: _currentFilters.sortOrder,
      );

      if (response.success && response.data != null) {
        final newPackages = response.data!.packages;
        final pagination = response.data!.pagination;
        
        List<Package> allPackages;
        if (_currentPage == 1) {
          allPackages = newPackages;
        } else {
          allPackages = [...state.packages, ...newPackages];
        }

        state = state.copyWith(
          packages: allPackages,
          pagination: pagination,
          isLoading: false,
          hasMore: pagination.hasMorePages,
          hasError: false,
        );

        _currentPage++;
      } else {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load packages: $e',
      );
    }
  }

  /// Load more packages (pagination)
  Future<void> loadMorePackages() async {
    if (!state.hasMore || state.isLoading) return;
    await loadPackages();
  }

  /// Apply filters and refresh
  Future<void> applyFilters(PackageFilters filters) async {
    _currentFilters = filters;
    await loadPackages(refresh: true);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    _currentFilters = PackageFilters();
    await loadPackages(refresh: true);
  }

  /// Get current filters
  PackageFilters get currentFilters => _currentFilters;
}

/// Package list provider
final packageListProvider = StateNotifierProvider<PackageListNotifier, PackageListState>((ref) {
  final packageService = ref.watch(packageServiceProvider);
  return PackageListNotifier(packageService);
});

/// Featured packages provider
final featuredPackagesProvider = FutureProvider<List<Package>>((ref) async {
  final packageService = ref.watch(packageServiceProvider);
  final response = await packageService.getFeaturedPackages();
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.message);
  }
});

/// Package categories provider
final packageCategoriesProvider = FutureProvider<PackageCategories>((ref) async {
  final packageService = ref.watch(packageServiceProvider);
  final response = await packageService.getCategories();
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.message);
  }
});

/// Package details provider
final packageDetailsProvider = FutureProviderFamily<Package, dynamic>((ref, packageId) async {
  final packageService = ref.watch(packageServiceProvider);
  final response = await packageService.getPackageDetails(packageId);
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.message);
  }
});

/// Search state
class SearchState {
  final List<Package> packages;
  final Pagination? pagination;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final String query;
  final bool hasMore;

  SearchState({
    this.packages = const [],
    this.pagination,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.query = '',
    this.hasMore = true,
  });

  SearchState copyWith({
    List<Package>? packages,
    Pagination? pagination,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    String? query,
    bool? hasMore,
  }) {
    return SearchState(
      packages: packages ?? this.packages,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final PackageService _packageService;
  int _currentPage = 1;
  static const int _pageSize = 20;

  SearchNotifier(this._packageService) : super(SearchState());

  /// Search packages
  Future<void> searchPackages(String query, {bool refresh = false}) async {
    if (query.trim().isEmpty) {
      state = SearchState();
      return;
    }

    if (refresh || query != state.query) {
      _currentPage = 1;
      state = state.copyWith(
        packages: [],
        query: query,
        hasMore: true,
        hasError: false,
      );
    }

    if (state.isLoading || (!state.hasMore && !refresh)) return;

    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final response = await _packageService.searchPackages(
        query: query.trim(),
        page: _currentPage,
        perPage: _pageSize,
      );

      if (response.success && response.data != null) {
        final newPackages = response.data!.packages;
        final pagination = response.data!.pagination;
        
        List<Package> allPackages;
        if (_currentPage == 1) {
          allPackages = newPackages;
        } else {
          allPackages = [...state.packages, ...newPackages];
        }

        state = state.copyWith(
          packages: allPackages,
          pagination: pagination,
          isLoading: false,
          hasMore: pagination.hasMorePages,
          hasError: false,
        );

        _currentPage++;
      } else {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Search failed: $e',
      );
    }
  }

  /// Load more search results
  Future<void> loadMoreResults() async {
    if (state.query.isEmpty || !state.hasMore || state.isLoading) return;
    await searchPackages(state.query);
  }

  /// Clear search
  void clearSearch() {
    state = SearchState();
    _currentPage = 1;
  }
}

/// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final packageService = ref.watch(packageServiceProvider);
  return SearchNotifier(packageService);
});