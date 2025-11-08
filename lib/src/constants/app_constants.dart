class AppConstants {
  // Environment Configuration
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  // Base URLs by Environment
  static const Map<String, String> _baseUrls = {
    'development': 'http://172.20.10.9:8000/api/v1',  // Changed from localhost to actual PC IP
    'staging': 'https://staging-api.seferet.com/api/v1',
    'production': 'https://api.seferet.com/api/v1',
  };
  
  // API Configuration
  static String get baseUrl => _baseUrls[_environment] ?? _baseUrls['development']!;
  static const String apiVersion = 'v1';
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  
  // Authentication Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';
  static const String profileEndpoint = '/profile';
  static const String customerDashboardEndpoint = '/customer/dashboard';
  
  // Package Endpoints
  static const String packagesEndpoint = '/packages';
  static const String packageSearchEndpoint = '/packages/search';
  static const String featuredPackagesEndpoint = '/packages/featured';
  static const String packageCategoriesEndpoint = '/packages/categories';
  static String packageDetailsEndpoint(dynamic id) => '/packages/$id';
  
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
}
