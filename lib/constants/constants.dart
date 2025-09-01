class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String apiVersion = 'v1';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';
  static const String profileEndpoint = '/profile';
  static const String customerDashboardEndpoint = '/customer/dashboard';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String rolePartner = 'partner';
  static const String roleAdmin = 'admin';
  
  // App Configuration
  static const String appName = 'SeferEt';
  static const String appVersion = '1.0.0';
  
  // Request Timeouts (in seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 255;
  static const int maxEmailLength = 255;
  static const int maxPhoneLength = 20;
  
  // Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  
  // Colors (as hex strings for easy use)
  static const String primaryColor = '#2E8B57'; // Sea Green
  static const String secondaryColor = '#FFD700'; // Gold
  static const String accentColor = '#87CEEB'; // Sky Blue
  static const String errorColor = '#FF6B6B';
  static const String successColor = '#4ECDC4';
  static const String warningColor = '#FFE66D';
}
