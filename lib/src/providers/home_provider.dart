import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/featured_product.dart';
import '../services/home_service.dart';
import 'auth_provider.dart';

/// Home data state
class HomeState {
  final List<FeaturedProduct> featuredProducts;
  final List<Recommendation> recommendations;
  final List<FeaturedProduct> popularProducts;
  final bool isLoadingFeatured;
  final bool isLoadingRecommendations;
  final bool isLoadingPopular;
  final String? featuredError;
  final String? recommendationsError;
  final String? popularError;

  const HomeState({
    this.featuredProducts = const [],
    this.recommendations = const [],
    this.popularProducts = const [],
    this.isLoadingFeatured = false,
    this.isLoadingRecommendations = false,
    this.isLoadingPopular = false,
    this.featuredError,
    this.recommendationsError,
    this.popularError,
  });

  HomeState copyWith({
    List<FeaturedProduct>? featuredProducts,
    List<Recommendation>? recommendations,
    List<FeaturedProduct>? popularProducts,
    bool? isLoadingFeatured,
    bool? isLoadingRecommendations,
    bool? isLoadingPopular,
    String? featuredError,
    String? recommendationsError,
    String? popularError,
  }) {
    return HomeState(
      featuredProducts: featuredProducts ?? this.featuredProducts,
      recommendations: recommendations ?? this.recommendations,
      popularProducts: popularProducts ?? this.popularProducts,
      isLoadingFeatured: isLoadingFeatured ?? this.isLoadingFeatured,
      isLoadingRecommendations: isLoadingRecommendations ?? this.isLoadingRecommendations,
      isLoadingPopular: isLoadingPopular ?? this.isLoadingPopular,
      featuredError: featuredError,
      recommendationsError: recommendationsError,
      popularError: popularError,
    );
  }

  bool get isLoading => isLoadingFeatured || isLoadingRecommendations || isLoadingPopular;
  bool get hasError => featuredError != null || recommendationsError != null || popularError != null;
  bool get isEmpty => featuredProducts.isEmpty && recommendations.isEmpty && popularProducts.isEmpty;
}

/// Home notifier for managing home screen data
class HomeNotifier extends StateNotifier<HomeState> {
  final HomeService _homeService;
  final String? _userId;

  HomeNotifier(this._homeService, this._userId) : super(const HomeState()) {
    _initializeData();
  }

  /// Initialize all home data
  Future<void> _initializeData() async {
    await Future.wait([
      loadFeaturedProducts(),
      loadRecommendations(),
      loadPopularProducts(),
    ]);
  }

  /// Load featured products
  Future<void> loadFeaturedProducts({bool forceRefresh = false}) async {
    state = state.copyWith(
      isLoadingFeatured: true,
      featuredError: null,
    );

    final response = await _homeService.getFeaturedProducts(
      forceRefresh: forceRefresh,
      perPage: 10,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(
        featuredProducts: response.data,
        isLoadingFeatured: false,
        featuredError: null,
      );
    } else {
      state = state.copyWith(
        isLoadingFeatured: false,
        featuredError: response.message,
      );
    }
  }

  /// Load recommendations (personalized for authenticated users, trending for guests)
  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    state = state.copyWith(
      isLoadingRecommendations: true,
      recommendationsError: null,
    );

    final response = await _homeService.getRecommendations(
      forceRefresh: forceRefresh,
      userId: _userId,
      limit: 10,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(
        recommendations: response.data,
        isLoadingRecommendations: false,
        recommendationsError: null,
      );
    } else {
      state = state.copyWith(
        isLoadingRecommendations: false,
        recommendationsError: response.message,
      );
    }
  }

  /// Load popular products
  Future<void> loadPopularProducts({bool forceRefresh = false, String? location}) async {
    state = state.copyWith(
      isLoadingPopular: true,
      popularError: null,
    );

    final response = await _homeService.getPopular(
      forceRefresh: forceRefresh,
      location: location,
      limit: 10,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(
        popularProducts: response.data,
        isLoadingPopular: false,
        popularError: null,
      );
    } else {
      state = state.copyWith(
        isLoadingPopular: false,
        popularError: response.message,
      );
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadFeaturedProducts(forceRefresh: true),
      loadRecommendations(forceRefresh: true),
      loadPopularProducts(forceRefresh: true),
    ]);
  }

  /// Clear error for a specific section
  void clearError(String section) {
    switch (section) {
      case 'featured':
        state = state.copyWith(featuredError: null);
        break;
      case 'recommendations':
        state = state.copyWith(recommendationsError: null);
        break;
      case 'popular':
        state = state.copyWith(popularError: null);
        break;
    }
  }
}

/// Provider for HomeService singleton
final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService();
});

/// Provider for home state
final homeNotifierProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final homeService = ref.watch(homeServiceProvider);
  // Get userId from auth provider if authenticated
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id.toString();
  return HomeNotifier(homeService, userId);
});
