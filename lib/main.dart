import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart' as provider show ChangeNotifierProvider;
import 'src/constants/app_constants.dart';
import 'src/constants/app_colors.dart';
import 'src/constants/app_theme.dart';
import 'src/services/api_service.dart';
import 'src/providers/hotel_provider.dart';
import 'src/views/splash_view.dart';
import 'src/features/auth/views/sign_in_view.dart';
import 'src/features/auth/views/sign_up_view.dart';
import 'src/views/onboarding_view.dart';
import 'src/views/home_view.dart';
import 'src/views/explore_view.dart';
import 'src/views/search_view.dart';
import 'src/views/favorites_view.dart';
import 'src/views/profile_view.dart';
import 'src/features/packages/views/tour_details_view.dart';
import 'src/features/hotels/views/hotel_list_page.dart';
import 'src/features/hotels/views/hotel_detail_page.dart';
import 'src/features/hotels/views/hotel_booking_page.dart';
import 'src/models/hotel_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service
  await ApiService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => HotelProvider()),
      ],
      child: const ProviderScope(
        child: SeferEtApp(),
      ),
    ),
  );
}

class SeferEtApp extends StatelessWidget {
  const SeferEtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: AppColors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
        ),
        useMaterial3: true,
        fontFamily: AppTheme.fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textTitleColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.textTitleColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge, 
              vertical: AppTheme.spacingMedium
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
          ),
        ),
      ),
      home: const SplashView(),
      routes: {
        '/splash': (context) => const SplashView(),
        '/onboarding': (context) => const OnboardingView(),
        '/sign-in': (context) => const SignInView(),
        '/sign-up': (context) => const SignUpView(),
        '/home': (context) => const HomeView(),
        '/explore-screen': (context) => const ExploreView(),
        '/flight-search': (context) => const SearchView(),
        '/favorites': (context) => const FavoritesView(),
        '/profile-screen': (context) => const ProfileView(),
        '/tour-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return TourDetailsView(destination: args);
        },
        '/search-details': (context) => const SearchView(),
        '/hotel-search': (context) => const HotelListPage(),
        '/hotel-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HotelDetailPage(
            hotelId: args?['hotelId'] as String? ?? '',
            hotel: args?['hotel'] as Hotel?,
          );
        },
        '/hotel-booking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return HotelBookingPage(
            hotel: args['hotel'] as Hotel,
            offer: args['offer'] as HotelOffer,
            checkIn: args['checkIn'] as DateTime?,
            checkOut: args['checkOut'] as DateTime?,
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// The SplashScreen logic is now handled by SplashView in lib/src/views/splash_view.dart
// This provides better separation of concerns and consistent theming.

