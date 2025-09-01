import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/constants.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service
  await ApiService().initialize();
  
  runApp(
    const ProviderScope(
      child: SeferEtApp(),
    ),
  );
}

class SeferEtApp extends StatelessWidget {
  const SeferEtApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(int.parse(AppConstants.primaryColor.substring(1), radix: 16) + 0xFF000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(int.parse(AppConstants.primaryColor.substring(1), radix: 16) + 0xFF000000),
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(int.parse(AppConstants.primaryColor.substring(1), radix: 16) + 0xFF000000),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(int.parse(AppConstants.primaryColor.substring(1), radix: 16) + 0xFF000000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    
    final apiService = ApiService();
    
    if (apiService.isAuthenticated) {
      // Check if token is still valid
      final userResponse = await apiService.getCurrentUser();
      
      if (userResponse.success) {
        // Navigate to appropriate dashboard based on role
        _navigateBasedOnRole(userResponse.data!.role);
      } else {
        // Token is invalid, navigate to login
        _navigateToLogin();
      }
    } else {
      // No token, navigate to login
      _navigateToLogin();
    }
  }

  void _navigateBasedOnRole(String role) {
    switch (role) {
      case AppConstants.roleCustomer:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerDashboard()),
        );
        break;
      case AppConstants.rolePartner:
      case AppConstants.roleAdmin:
        // For now, partners and admins use web interface
        _showWebInterfaceMessage(role);
        break;
      default:
        _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showWebInterfaceMessage(String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${role.toUpperCase()} Access'),
        content: Text('$role accounts should use the web interface. This mobile app is designed for customers.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(int.parse(AppConstants.primaryColor.substring(1), radix: 16) + 0xFF000000),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mosque,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Umrah Booking Made Easy',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens - these would be implemented in separate files
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Text('Login Screen - To be implemented'),
      ),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Text('Customer Dashboard - To be implemented'),
      ),
    );
  }
}
