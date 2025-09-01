# SeferEt Flutter Mobile App

Flutter mobile application for the SeferEt Umrah booking system. This app provides a native mobile experience for customers to browse and book Umrah packages.

## Overview

The SeferEt Flutter app is designed specifically for **customers** and connects to the Laravel backend API. Partners and administrators should use the web interface for their respective dashboards.

## Features

- **Customer Authentication**: Login/register with role-based access
- **Package Browsing**: Browse available Umrah packages
- **Booking Management**: Create and manage bookings
- **Profile Management**: Update user profile and preferences
- **Offline Support**: Basic offline functionality with local storage
- **Multi-language Support**: English, Arabic, Turkish, Urdu

## Project Structure

```
SeferEt-Flutter/
├── lib/
│   ├── constants/
│   │   └── constants.dart       # App-wide constants and configuration
│   ├── models/
│   │   └── user.dart           # User model
│   ├── services/
│   │   └── api_service.dart    # HTTP API service with authentication
│   ├── screens/
│   │   ├── auth/               # Authentication screens
│   │   └── customer/           # Customer-specific screens
│   ├── widgets/
│   │   └── common/             # Reusable widgets
│   ├── utils/                  # Utility functions
│   └── main.dart              # App entry point
├── android/                    # Android-specific configuration
├── ios/                       # iOS-specific configuration
├── assets/
│   ├── images/                # Image assets
│   ├── icons/                 # Icon assets
│   └── animations/            # Animation assets
└── test/                      # Test files
```

## Architecture

### State Management
- **Riverpod**: For global state management
- **Provider**: For widget-level state management

### Networking
- **HTTP Package**: For API communication
- **Dio**: Alternative HTTP client with interceptors

### Local Storage
- **SharedPreferences**: For simple key-value storage (tokens, settings)
- **Hive**: For complex local data storage

### Navigation
- **GoRouter**: For declarative routing and deep linking

## Installation & Setup

1. **Prerequisites**
   - Flutter SDK (>=3.0.0)
   - Dart SDK
   - Android Studio / Xcode for device testing

2. **Clone and setup**
   ```bash
   git clone <repository-url> SeferEt-Flutter
   cd SeferEt-Flutter
   flutter pub get
   ```

3. **Configure API endpoint**
   Update the `baseUrl` in `lib/constants/constants.dart`:
   ```dart
   static const String baseUrl = 'https://your-api-domain.com/api/v1';
   ```

4. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

## API Integration

The app communicates with the Laravel backend through the `ApiService` class:

```dart
// Example usage
final apiService = ApiService();

// Login
final response = await apiService.login('email@example.com', 'password');

// Get current user
final userResponse = await apiService.getCurrentUser();

// Get customer dashboard
final dashboardResponse = await apiService.getCustomerDashboard();
```

## Authentication Flow

1. **Token Storage**: Authentication tokens are stored securely using SharedPreferences
2. **Automatic Headers**: API service automatically includes Bearer token in requests
3. **Token Refresh**: Handles token refresh automatically
4. **Role Validation**: App validates user role and redirects accordingly

## Configuration

### API Constants
All API-related constants are centralized in `lib/constants/constants.dart`:
- Base URL and endpoints
- Timeout configurations
- Storage keys
- App-wide settings

### Environment-Specific Builds
You can create different configurations for development, staging, and production:

```dart
// Development
static const String baseUrl = 'http://localhost:8000/api/v1';

// Production
static const String baseUrl = 'https://api.seferet.com/api/v1';
```

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Dependencies

### Core Dependencies
- `flutter_riverpod`: State management
- `http`: HTTP requests
- `shared_preferences`: Local storage
- `go_router`: Navigation

### UI Dependencies
- `google_fonts`: Custom fonts
- `flutter_svg`: SVG support
- `cached_network_image`: Image caching

### Development Dependencies
- `flutter_lints`: Code linting
- `very_good_analysis`: Enhanced linting rules

## Contributing

1. Follow Flutter/Dart style guidelines
2. Write tests for new features
3. Update documentation for API changes
4. Use semantic versioning for releases

## Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)

### iOS
- Minimum deployment target: iOS 12.0
- Requires Xcode 14.0 or later

## Troubleshooting

### Common Issues
1. **API Connection**: Ensure the Laravel backend is running and accessible
2. **Token Expiration**: The app handles token refresh automatically
3. **Platform Permissions**: Check camera, storage permissions for file uploads

### Debug Mode
Enable debug mode in constants for additional logging:
```dart
static const bool debugMode = true;
```
