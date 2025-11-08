import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../models/featured_product.dart';
import '../services/home_service.dart';
import '../widgets/ad_block_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MainView extends ConsumerStatefulWidget {
  final Function(int, {int? tabIndex, String? fromText, String? toText})? onNavigateToSearch;
  
  const MainView({super.key, this.onNavigateToSearch});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.98);
  late TabController _tabController;
  
  // Flight Search Controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime _departureDate = DateTime.now().add(const Duration(days: 7));
  
  // Umrah Package Controllers
  final TextEditingController _umrahDestinationController = TextEditingController();
  DateTime _umrahDepartureDate = DateTime.now().add(const Duration(days: 30));
  
  // Hotel Search Controllers
  final TextEditingController _hotelDestinationController = TextEditingController();
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 9));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _umrahDestinationController.dispose();
    _hotelDestinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeNotifierProvider.notifier).refreshAll();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 6,
          ),
          child: Stack(
            children: [
              _buildTopBackground(context),
              _buildGradientOverlay(context),
              _buildTopBar(authState),
              _buildNotificationButton(),
              _buildMainContent(context, homeState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBackground(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/topbar_background.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.backgroundColor],
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthState authState) {
    final userName = authState.isAuthenticated && authState.user != null
        ? authState.user!.name
        : 'Guest';
    final userCountry = authState.isAuthenticated && authState.user != null
        ? authState.user!.country ?? 'Welcome'
        : 'Welcome';
    
    return Positioned(
      top: 40,
      left: AppTheme.spacingLarge,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile-screen'),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(30)),
                image: DecorationImage(
                  image: AssetImage("assets/images/profile.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $userName',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitleColor,
                ),
              ),
              Text(
                userCountry,
                style: AppTheme.labelLarge.copyWith(
                  color: AppColors.textTitleColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Positioned(
      top: 40,
      right: AppTheme.spacingLarge,
      child: Stack(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textTitleColor,
              size: AppTheme.iconSizeLarge,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.errorColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, HomeState homeState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.14),
          _buildSearchForm(),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildCategoryIcons(),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildPromotionCards(context),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildPageIndicator(),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildPopularNearbySection(homeState),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildRecommendationSection(homeState),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Column(
      children: [
        _buildTabBar(),
        SizedBox(
          height: 205, // Increased height to prevent overflow
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUmrahPackageForm(),
              _buildFlightSearchForm(),
              _buildHotelSearchForm(),
            ],
          ),
        ),
      ],
    );
  }
  
  // Tab Bar Widget
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.primaryColor,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: AppColors.primaryColor,
      unselectedLabelColor: AppColors.backgroundColor,
      labelStyle: AppTheme.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: AppTheme.bodyMedium.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 18,
      ),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Umrah'),
        Tab(text: 'Flights'),
        Tab(text: 'Hotels'),
      ],
    );
  }
  
  // Minimal Umrah Package Form (only destination and date)
  Widget _buildUmrahPackageForm() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingMedium,
        bottom: AppTheme.spacingMedium,
      ),
      child: Column(
        children: [
          _buildCompactTextField(
            controller: _umrahDestinationController,
            label: 'Destination',
            hint: 'Makkah, Madinah',
            prefixIcon: Icons.mosque,
          ),
          const SizedBox(height: 12),
          _buildCompactDateSelector(
            label: 'Departure Date',
            date: _umrahDepartureDate,
            onTap: () => _selectUmrahDate(context),
          ),
          const SizedBox(height: 14),
          _buildCompactButton('Search Packages'),
        ],
      ),
    );
  }
  
  // Minimal Flight Search Form
  Widget _buildFlightSearchForm() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingMedium,
        bottom: AppTheme.spacingMedium,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _fromController,
                  label: 'From',
                  hint: 'Departure',
                  prefixIcon: Icons.flight_takeoff,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactTextField(
                  controller: _toController,
                  label: 'To',
                  hint: 'Destination',
                  prefixIcon: Icons.flight_land,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCompactDateSelector(
            label: 'Departure Date',
            date: _departureDate,
            onTap: () => _selectFlightDate(context),
          ),
          const SizedBox(height: 14),
          _buildCompactButton('Search Flights'),
        ],
      ),
    );
  }
  
  // Minimal Hotel Search Form
  Widget _buildHotelSearchForm() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingMedium,
        bottom: AppTheme.spacingMedium,
      ),
      child: Column(
        children: [
          _buildCompactTextField(
            controller: _hotelDestinationController,
            label: 'Destination',
            hint: 'City or hotel name',
            prefixIcon: Icons.hotel,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactDateSelector(
                  label: 'Check-in',
                  date: _checkInDate,
                  onTap: () => _selectCheckInDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactDateSelector(
                  label: 'Check-out',
                  date: _checkOutDate,
                  onTap: () => _selectCheckOutDate(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCompactButton('Search Hotels'),
        ],
      ),
    );
  }
  
  // Ultra-Compact Helper Methods
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border.all(color: AppColors.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyMedium.copyWith(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTheme.bodySmall.copyWith(
            color: AppColors.primaryColor,
            fontSize: 11,
          ),
          hintStyle: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
            fontSize: 11,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.primaryColor, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
      ),
    );
  }
  
  Widget _buildCompactDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          border: Border.all(color: AppColors.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildCompactButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
        ),
        onPressed: () {
          _navigateToSearchPage();
        },
        child: Text(
          text,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.backgroundColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  // Date Selection Methods
  Future<void> _selectUmrahDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _umrahDepartureDate,
      firstDate: DateTime.now().add(const Duration(days: 14)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _umrahDepartureDate = picked;
      });
    }
  }
  
  Future<void> _selectFlightDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
      });
    }
  }
  
  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate.add(const Duration(days: 1)))) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }
  
  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }
  
  // Navigation to Search Page
  void _navigateToSearchPage() {
    // Use the callback to notify HomeView to switch to search tab
    if (widget.onNavigateToSearch != null) {
      widget.onNavigateToSearch!(
        2, // SearchView is at index 2 in HomeView
        tabIndex: _tabController.index,
        fromText: _fromController.text,
        toText: _toController.text,
      );
    }
  }

  Widget _buildCategoryIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCategoryIcon(
            Icons.airplane_ticket_outlined, 'Flight', '/flight-search'),
        _buildCategoryIcon(Icons.hotel_outlined, 'Hotels', '/explore-screen'),
        _buildCategoryIcon(Icons.map_outlined, 'Guide', '/explore-screen'),
        _buildCategoryIcon(Icons.more_outlined, 'More', '/explore-screen'),
      ],
    );
  }

  Widget _buildCategoryIcon(IconData icon, String label, String route) {
    return Column(
      children: [
        InkWell(
          splashColor: AppColors.secondaryColor,
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            radius: 30,
            child: Icon(
              icon,
              color: AppColors.textTitleColor,
              size: AppTheme.iconSizeLarge,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCards(BuildContext context) {
    return AdBlockWidget(
      placement: 'home_banner',
      height: 180,
      autoRotate: true,
      autoRotateInterval: const Duration(seconds: 5),
      fallbackWidget: _buildFallbackPromoCard(context),
    );
  }

  /// Fallback widget when no ads are available
  Widget _buildFallbackPromoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.87,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          image: const DecorationImage(
            image: AssetImage('assets/images/promo_banner.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(130, 48),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: AppColors.backgroundColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
                  ),
                  backgroundColor: AppColors.primaryColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Get Now",
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.backgroundColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    const Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios_sharp,
                          size: 12,
                          color: AppColors.backgroundColor,
                        ),
                        Icon(
                          Icons.arrow_forward_ios_sharp,
                          size: 12,
                          color: AppColors.backgroundColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dividerColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularNearbySection(HomeState homeState) {
    return Column(
      children: [
        _buildSectionTitle('Featured Products'),
        const SizedBox(height: AppTheme.spacingMedium),
        _buildFeaturedProductsList(homeState),
      ],
    );
  }
  
  Widget _buildFeaturedProductsList(HomeState homeState) {
    if (homeState.isLoadingFeatured) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (homeState.featuredError != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                homeState.featuredError!,
                style: AppTheme.bodyMedium.copyWith(color: AppColors.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              ElevatedButton(
                onPressed: () {
                  ref.read(homeNotifierProvider.notifier).loadFeaturedProducts(forceRefresh: true);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (homeState.featuredProducts.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No featured products available'),
        ),
      );
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeState.featuredProducts.length,
        itemBuilder: (context, index) {
          final product = homeState.featuredProducts[index];
          return _buildFeaturedProductCard(product);
        },
      ),
    );
  }

  Widget _buildRecommendationSection(HomeState homeState) {
    return Column(
      children: [
        _buildSectionTitle('Recommended for You'),
        const SizedBox(height: AppTheme.spacingMedium),
        _buildRecommendationsList(homeState),
      ],
    );
  }
  
  Widget _buildRecommendationsList(HomeState homeState) {
    if (homeState.isLoadingRecommendations) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (homeState.recommendationsError != null) {
      return SizedBox(
        height: 130,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                homeState.recommendationsError!,
                style: AppTheme.bodyMedium.copyWith(color: AppColors.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextButton(
                onPressed: () {
                  ref.read(homeNotifierProvider.notifier).loadRecommendations(forceRefresh: true);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (homeState.recommendations.isEmpty) {
      return const SizedBox(
        height: 130,
        child: Center(
          child: Text('No recommendations available'),
        ),
      );
    }
    
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: homeState.recommendations.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppTheme.spacingMedium),
        itemBuilder: (context, index) {
          final recommendation = homeState.recommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/explore-screen'),
          child: Text(
            "See More",
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductCard(FeaturedProduct product) {
    final homeService = HomeService();
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          homeService.getDetailRoute(product.type),
          arguments: homeService.getNavigationArgs(product),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppTheme.spacingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          color: AppColors.fadedTextColor.withOpacity(0.1),
          image: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(product.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                )
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            gradient: LinearGradient(
              colors: [
                AppColors.blackTransparent,
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.6],
            ),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(
                        product.badge!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.backgroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (product.source == 'amadeus')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        product.typeLabel,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.backgroundColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppColors.textTitleColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.location != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.backgroundColor,
                                size: 16,
                              ),
                              Expanded(
                                child: Text(
                                  product.location!,
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppColors.textTitleColor.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        if (product.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.warningColor,
                                size: AppTheme.iconSizeSmall,
                              ),
                              const SizedBox(width: AppTheme.spacingXSmall),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: AppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningColor,
                                ),
                              ),
                              if (product.reviewCount != null)
                                const SizedBox(width: AppTheme.spacingXSmall),
                              if (product.reviewCount != null)
                                Text(
                                  '(${product.reviewCount})',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.textTitleColor,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Flexible(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 2, right: AppTheme.spacingMedium),
                      child: InkWell(
                        splashColor: AppColors.blackTransparent,
                        onTap: () {},
                        child: const Icon(
                          Icons.favorite_border,
                          color: AppColors.textTitleColor,
                          size: 26,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.priceFormatted,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppColors.textTitleColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    final homeService = HomeService();
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          homeService.getDetailRoute(recommendation.type),
          arguments: {
            'id': recommendation.id,
            'type': recommendation.type,
            'source': recommendation.source,
          },
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: AppColors.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.spacingSmall),
              child: recommendation.imageUrl != null && recommendation.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: recommendation.imageUrl!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 120,
                        color: AppColors.fadedTextColor.withOpacity(0.1),
                        child: const Icon(Icons.image, size: 30),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 120,
                        color: AppColors.fadedTextColor.withOpacity(0.1),
                        child: const Icon(Icons.broken_image, size: 30),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: AppColors.fadedTextColor.withOpacity(0.1),
                      child: const Icon(Icons.image, size: 30),
                    ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recommendation.reasonTag,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (recommendation.location != null)
                    const SizedBox(height: AppTheme.spacingXSmall),
                  if (recommendation.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.fadedTextColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            recommendation.location!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.fadedTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (recommendation.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.warningColor,
                          size: AppTheme.iconSizeSmall,
                        ),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          recommendation.rating!.toStringAsFixed(1),
                          style: AppTheme.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    recommendation.priceFormatted,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
