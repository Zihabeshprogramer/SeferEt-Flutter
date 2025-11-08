# Ad System Documentation

## Overview

The ad system provides a comprehensive solution for displaying, tracking, and managing advertisements in the SeferEt Flutter app. It includes support for multiple image densities, customizable CTAs, deep linking, and robust tracking with caching.

## Architecture

### Components

1. **Models** (`lib/src/models/ad_simple.dart`)
   - `Ad`: Main ad model with metadata, images, CTA, and tracking
   - `AdImageVariant`: Image variants for different screen densities
   - `AdCTA`: Call-to-action button configuration
   - `AdPosition`: Normalized positioning for CTA placement
   - `AdCTAStyle`: Complete styling configuration for CTA buttons
   - `AdTracking`: Tracking URLs for impressions and clicks

2. **Services** (`lib/src/services/ad_service.dart`)
   - Fetch active ads from API
   - Local caching with expiration (15 minutes)
   - Impression and click tracking with retry logic
   - Failed tracking persistence for offline scenarios

3. **Utilities** (`lib/src/utils/deep_link_handler.dart`)
   - Internal route navigation with safety checks
   - External URL handling with security validation
   - Deep link parsing and validation

4. **Widgets** (`lib/src/widgets/ad_block_widget.dart`)
   - `AdBlockWidget`: Main ad carousel with auto-rotation
   - Automatic impression tracking (50% visibility threshold)
   - Click tracking and CTA handling
   - Responsive image selection based on device pixel ratio
   - Graceful fallback for no-ads scenarios

## API Integration

### Expected API Endpoints

```
GET /api/v1/ads/active
Query Parameters:
  - placement: string (e.g., 'home_banner')
  - limit: integer (default: 5)
  - active: boolean (default: true)

Response Format:
{
  "success": true,
  "message": "Ads retrieved successfully",
  "data": [
    {
      "id": "ad-123",
      "name": "Summer Sale Campaign",
      "description": "Special summer offers",
      "image_variants": [
        {
          "image_url": "https://cdn.example.com/ad-1x.jpg",
          "density": 1.0,
          "width": 800,
          "height": 400,
          "file_size": 125000
        },
        {
          "image_url": "https://cdn.example.com/ad-2x.jpg",
          "density": 2.0,
          "width": 1600,
          "height": 800,
          "file_size": 450000
        },
        {
          "image_url": "https://cdn.example.com/ad-3x.jpg",
          "density": 3.0,
          "width": 2400,
          "height": 1200,
          "file_size": 950000
        }
      ],
      "cta": {
        "text": "Book Now",
        "target_url": "/package-detail/123",
        "type": "internal",
        "position": {
          "x": 0.1,
          "y": 0.85,
          "alignment": "start"
        },
        "style": {
          "background_color": "#FF6B35",
          "text_color": "#FFFFFF",
          "border_radius": 24,
          "padding": 16,
          "font_size": 16,
          "font_weight": "bold",
          "border": {
            "color": "#FFFFFF",
            "width": 2
          },
          "shadow": {
            "color": "#00000040",
            "blur_radius": 8,
            "offset_x": 0,
            "offset_y": 4
          }
        }
      },
      "tracking_urls": {
        "impression_url": "https://api.example.com/track/impression",
        "click_url": "https://api.example.com/track/click",
        "pixels": [
          "https://analytics.example.com/pixel.gif?id=ad-123"
        ]
      },
      "priority": 10,
      "start_date": "2025-01-01T00:00:00Z",
      "end_date": "2025-12-31T23:59:59Z",
      "target": "all",
      "metadata": {
        "campaign_id": "summer-2025",
        "advertiser": "Partner XYZ"
      }
    }
  ]
}
```

### Tracking Endpoints

The system will POST to the tracking URLs with the following payload:

```json
{
  "ad_id": "ad-123",
  "timestamp": "2025-01-08T20:30:00.000Z",
  "type": "impression" // or "click"
}
```

## Usage

### Basic Implementation

```dart
import 'package:seferet_flutter/src/widgets/ad_block_widget.dart';

// In your widget tree
AdBlockWidget(
  placement: 'home_banner',
  height: 180,
  autoRotate: true,
  autoRotateInterval: const Duration(seconds: 5),
  fallbackWidget: YourFallbackWidget(),
)
```

### Custom Configuration

```dart
AdBlockWidget(
  placement: 'search_results',
  height: 200,
  width: MediaQuery.of(context).size.width * 0.9,
  margin: const EdgeInsets.symmetric(horizontal: 16),
  borderRadius: BorderRadius.circular(16),
  autoRotate: false,
  fallbackWidget: Container(
    height: 200,
    color: Colors.grey[200],
    child: const Center(child: Text('No ads available')),
  ),
)
```

## Features

### Image Density Selection

The system automatically selects the best image variant based on the device's pixel ratio:

- **1.0x**: mdpi (baseline)
- **1.5x**: hdpi
- **2.0x**: xhdpi
- **3.0x**: xxhdpi
- **4.0x**: xxxhdpi

The algorithm selects the closest higher density variant to ensure crisp images without excessive bandwidth usage.

### CTA Positioning

CTA buttons are positioned using normalized coordinates (0.0 to 1.0):

- `x: 0.0` = left edge, `x: 1.0` = right edge
- `y: 0.0` = top edge, `y: 1.0` = bottom edge

Example positions:
- Bottom-left: `{x: 0.1, y: 0.85}`
- Center: `{x: 0.5, y: 0.5}`
- Top-right: `{x: 0.9, y: 0.15}`

### Deep Linking

#### Internal Routes
```json
{
  "type": "internal",
  "target_url": "/package-detail/123"
}
```

Safe internal routes (see `deep_link_handler.dart` for complete list):
- `/flight-search`, `/flight-detail`, `/flight-booking`
- `/hotel-search`, `/hotel-detail`
- `/tour-details`, `/package-detail`
- `/profile-screen`, `/my-bookings`, `/favorites`

#### External URLs
```json
{
  "type": "external",
  "target_url": "https://example.com/promotion"
}
```

Only `http` and `https` schemes are allowed for security.

### Tracking

#### Impression Tracking
- Automatically triggered when ad is 50%+ visible
- Tracked once per session (in-memory deduplication)
- Retries up to 3 times on failure
- Failed tracking stored for later retry

#### Click Tracking
- Triggered on CTA tap
- Fire-and-forget (doesn't block navigation)
- Session-based deduplication
- Automatic retry for failed tracking

### Caching

#### Ad Cache
- **Duration**: 15 minutes
- **Storage**: SharedPreferences
- **Key**: `ad_cache`
- **Fallback**: Uses cache on network failure

#### Tracking Cache
- Stores failed impression/click tracking
- **Limit**: Last 100 failed events
- **Auto-retry**: On next app launch or network change

## Accessibility

The CTA buttons meet WCAG accessibility guidelines:

- **Minimum tappable size**: 44x44 points (iOS) / 48x48 dp (Android)
- **Semantic labels**: Properly labeled for screen readers
- **Color contrast**: Configurable via server-side styling

## Performance

### Optimizations

1. **Image Caching**: Uses `cached_network_image` for efficient image management
2. **Lazy Loading**: Images loaded only when needed
3. **Minimal Layout Shifts**: Fixed heights prevent content jumping
4. **Async Tracking**: Non-blocking tracking calls
5. **Memory Efficiency**: In-memory deduplication using Sets

### Bandwidth Considerations

- Density-aware image selection reduces unnecessary data usage
- File size information available for bandwidth-aware loading
- Images cached on device after first load

## Testing

### Unit Testing Ad Models

```dart
test('Ad model parses JSON correctly', () {
  final json = {
    'id': 'ad-1',
    'name': 'Test Ad',
    'image_variants': [
      {'image_url': 'test.jpg', 'density': 1.0, 'width': 800, 'height': 400}
    ],
    'tracking_urls': {},
  };
  
  final ad = Ad.fromJson(json);
  expect(ad.id, 'ad-1');
  expect(ad.imageVariants.length, 1);
});
```

### Integration Testing

```dart
testWidgets('AdBlockWidget shows fallback when no ads', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdBlockWidget(
          fallbackWidget: const Text('No ads'),
        ),
      ),
    ),
  );
  
  // Wait for loading
  await tester.pumpAndSettle();
  
  // Verify fallback is shown
  expect(find.text('No ads'), findsOneWidget);
});
```

## Server-Side Implementation Guide

### Creating Ad Campaigns

1. **Upload Image Variants**: Create multiple density versions
2. **Configure CTA**: Set text, position, style, and target
3. **Set Tracking URLs**: Configure impression/click endpoints
4. **Define Active Period**: Set start and end dates
5. **Set Priority**: Higher priority ads shown first

### Best Practices

1. **Image Sizes**:
   - 1x: 800x400px (max 150KB)
   - 2x: 1600x800px (max 500KB)
   - 3x: 2400x1200px (max 1MB)

2. **CTA Design**:
   - Keep text short (max 20 characters)
   - Use high contrast colors
   - Position away from image edges (10% margin)

3. **Tracking**:
   - Return 200 OK quickly (< 100ms)
   - Handle duplicate events gracefully
   - Log all tracking data for analytics

## Troubleshooting

### Ads Not Showing

1. Check API endpoint is reachable
2. Verify ad is within active date range
3. Check placement parameter matches server
4. Review console logs for errors

### Tracking Not Working

1. Verify tracking URLs are accessible
2. Check network connectivity
3. Review failed tracking cache
4. Ensure tracking endpoints return 2xx status

### Images Not Loading

1. Verify image URLs are accessible
2. Check CORS settings on image server
3. Ensure HTTPS for production images
4. Check device storage permissions

## Future Enhancements

- [ ] A/B testing support
- [ ] Video ad support
- [ ] Animated ad banners
- [ ] User-level ad frequency capping
- [ ] Advanced targeting (location, demographics)
- [ ] Analytics dashboard integration
- [ ] Ad blocker detection
- [ ] Native ad formats
