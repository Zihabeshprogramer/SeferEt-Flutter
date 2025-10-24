import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class MainView extends StatefulWidget {
  final Function(int, {int? tabIndex, String? fromText, String? toText})? onNavigateToSearch;
  
  const MainView({super.key, this.onNavigateToSearch});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        child: Stack(
          children: [
            _buildTopBackground(context),
            _buildGradientOverlay(context),
            _buildTopBar(),
            _buildNotificationButton(),
            _buildMainContent(context),
          ],
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

  Widget _buildTopBar() {
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
                'Hi, Ana Acker',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitleColor,
                ),
              ),
              Text(
                'Netherlands',
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

  Widget _buildMainContent(BuildContext context) {
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
          _buildPopularNearbySection(),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildRecommendationSection(),
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
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: PageView(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        children: [
          _buildPromoCard(context, 'assets/images/promo_banner.png'),
          _buildPromoCard(context, 'assets/images/promo_banner.png'),
          _buildPromoCard(context, 'assets/images/promo_banner.png'),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.87,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            image: DecorationImage(
              image: AssetImage(imagePath),
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

  Widget _buildPopularNearbySection() {
    return Column(
      children: [
        _buildSectionTitle('Popular Nearby'),
        const SizedBox(height: AppTheme.spacingMedium),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildLocationCard('Male City', 'Maldives', 138),
              _buildLocationCard('Perhentian Islands', 'Malaysia', 218),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      children: [
        _buildSectionTitle('Recommendation'),
        const SizedBox(height: AppTheme.spacingMedium),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRecommendationCard('Eiffel Tower', 'Paris, France', 138),
              const SizedBox(width: AppTheme.spacingMedium),
              _buildRecommendationCard('Santorini', 'Greece', 198),
            ],
          ),
        ),
      ],
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

  Widget _buildLocationCard(String title, String location, int price) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/tour-details');
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppTheme.spacingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          image: const DecorationImage(
            image: AssetImage('assets/images/eiffel_tower.png'),
            fit: BoxFit.cover,
          ),
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
                  Container(
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.dividerColor.withOpacity(0.6),
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "10%",
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.backgroundColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "OFF",
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.backgroundColor,
                          ),
                        ),
                      ],
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
                          title,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppColors.textTitleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.backgroundColor,
                              size: AppTheme.iconSizeMedium -
                                  AppTheme.spacingSmall,
                            ),
                            Text(
                              location,
                              style: AppTheme.labelLarge.copyWith(
                                color:
                                    AppColors.textTitleColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.warningColor,
                              size: AppTheme.iconSizeSmall,
                            ),
                            const SizedBox(width: AppTheme.spacingXSmall),
                            Text(
                              '4.8',
                              style: AppTheme.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningColor,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingXSmall),
                            Text(
                              '(32)',
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
              Column(
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
                    "\$$price",
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppColors.textTitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String location, int price) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/tour-details');
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
              child: Image.asset(
                'assets/images/eiffel_tower.png',
                width: 80,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.fadedTextColor,
                        size: AppTheme.iconSizeMedium - AppTheme.spacingSmall,
                      ),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        location,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.fadedTextColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.warningColor,
                        size: AppTheme.iconSizeSmall,
                      ),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        '4.8',
                        style: AppTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        '(32)',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.fadedTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      Text(
                        '\$138',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '\$198',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppColors.errorColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
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
