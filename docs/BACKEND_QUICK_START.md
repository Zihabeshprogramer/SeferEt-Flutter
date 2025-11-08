# Backend Quick Start Guide for Ad System

This guide helps backend developers quickly implement the required endpoints for the Flutter ad system.

## Required Endpoints

### 1. Get Active Ads

```
GET /api/v1/ads/active
```

#### Query Parameters:
- `placement` (optional): Ad placement identifier (e.g., "home_banner", "search_results")
- `limit` (optional): Maximum number of ads to return (default: 5)
- `active` (optional): Filter for active ads only (default: true)

#### Response Example:

```json
{
  "success": true,
  "message": "Ads retrieved successfully",
  "data": [
    {
      "id": "ad-001",
      "name": "Umrah Package Promotion",
      "description": "Special winter Umrah packages",
      "image_variants": [
        {
          "image_url": "https://cdn.yourdomain.com/ads/ad-001-1x.jpg",
          "density": 1.0,
          "width": 800,
          "height": 400,
          "file_size": 125000
        },
        {
          "image_url": "https://cdn.yourdomain.com/ads/ad-001-2x.jpg",
          "density": 2.0,
          "width": 1600,
          "height": 800,
          "file_size": 450000
        },
        {
          "image_url": "https://cdn.yourdomain.com/ads/ad-001-3x.jpg",
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
        "impression_url": "https://api.yourdomain.com/api/v1/ads/track/impression",
        "click_url": "https://api.yourdomain.com/api/v1/ads/track/click",
        "pixels": [
          "https://analytics.example.com/pixel.gif?id=ad-001"
        ]
      },
      "priority": 10,
      "start_date": "2025-01-01T00:00:00Z",
      "end_date": "2025-12-31T23:59:59Z",
      "target": "all",
      "metadata": {
        "campaign_id": "winter-2025",
        "advertiser": "In-house"
      }
    }
  ]
}
```

### 2. Track Impression

```
POST /api/v1/ads/track/impression
```

#### Request Body:
```json
{
  "ad_id": "ad-001",
  "timestamp": "2025-01-08T20:30:00.000Z",
  "type": "impression"
}
```

#### Response:
```json
{
  "success": true,
  "message": "Impression tracked"
}
```

### 3. Track Click

```
POST /api/v1/ads/track/click
```

#### Request Body:
```json
{
  "ad_id": "ad-001",
  "timestamp": "2025-01-08T20:30:15.000Z",
  "type": "click"
}
```

#### Response:
```json
{
  "success": true,
  "message": "Click tracked"
}
```

## Database Schema Example

### ads table
```sql
CREATE TABLE ads (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    priority INT DEFAULT 0,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    target VARCHAR(50),
    placement VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### ad_images table
```sql
CREATE TABLE ad_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id VARCHAR(50) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    density DECIMAL(3,1) NOT NULL,
    width INT NOT NULL,
    height INT NOT NULL,
    file_size INT,
    FOREIGN KEY (ad_id) REFERENCES ads(id) ON DELETE CASCADE,
    INDEX idx_ad_density (ad_id, density)
);
```

### ad_ctas table
```sql
CREATE TABLE ad_ctas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id VARCHAR(50) NOT NULL UNIQUE,
    text VARCHAR(100) NOT NULL,
    target_url VARCHAR(500) NOT NULL,
    type ENUM('internal', 'external') NOT NULL,
    position_x DECIMAL(3,2) NOT NULL,
    position_y DECIMAL(3,2) NOT NULL,
    alignment VARCHAR(20),
    style_json JSON,
    FOREIGN KEY (ad_id) REFERENCES ads(id) ON DELETE CASCADE
);
```

### ad_tracking table
```sql
CREATE TABLE ad_tracking (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id VARCHAR(50) NOT NULL,
    impression_url VARCHAR(500),
    click_url VARCHAR(500),
    pixels JSON,
    FOREIGN KEY (ad_id) REFERENCES ads(id) ON DELETE CASCADE
);
```

### ad_events table (for analytics)
```sql
CREATE TABLE ad_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ad_id VARCHAR(50) NOT NULL,
    event_type ENUM('impression', 'click') NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    user_id INT,
    device_info JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ad_type (ad_id, event_type),
    INDEX idx_timestamp (timestamp)
);
```

## Laravel Implementation Example

### Controller

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Ad;
use App\Models\AdEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdController extends Controller
{
    /**
     * Get active ads
     */
    public function getActive(Request $request)
    {
        $request->validate([
            'placement' => 'nullable|string|max:50',
            'limit' => 'nullable|integer|min:1|max:20',
            'active' => 'nullable|boolean',
        ]);

        $placement = $request->input('placement');
        $limit = $request->input('limit', 5);
        
        $query = Ad::with(['images', 'cta', 'tracking'])
            ->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('start_date')
                  ->orWhere('start_date', '<=', now());
            })
            ->where(function ($q) {
                $q->whereNull('end_date')
                  ->orWhere('end_date', '>=', now());
            })
            ->orderBy('priority', 'desc');

        if ($placement) {
            $query->where('placement', $placement);
        }

        $ads = $query->limit($limit)->get();

        return response()->json([
            'success' => true,
            'message' => 'Ads retrieved successfully',
            'data' => $ads->map(function ($ad) {
                return $ad->toApiFormat();
            }),
        ]);
    }

    /**
     * Track impression
     */
    public function trackImpression(Request $request)
    {
        $request->validate([
            'ad_id' => 'required|string|exists:ads,id',
            'timestamp' => 'required|date',
            'type' => 'required|in:impression',
        ]);

        AdEvent::create([
            'ad_id' => $request->ad_id,
            'event_type' => 'impression',
            'timestamp' => $request->timestamp,
            'user_id' => auth()->id(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Impression tracked',
        ]);
    }

    /**
     * Track click
     */
    public function trackClick(Request $request)
    {
        $request->validate([
            'ad_id' => 'required|string|exists:ads,id',
            'timestamp' => 'required|date',
            'type' => 'required|in:click',
        ]);

        AdEvent::create([
            'ad_id' => $request->ad_id,
            'event_type' => 'click',
            'timestamp' => $request->timestamp,
            'user_id' => auth()->id(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Click tracked',
        ]);
    }
}
```

### Model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ad extends Model
{
    protected $fillable = [
        'id', 'name', 'description', 'priority', 
        'start_date', 'end_date', 'target', 'placement', 'is_active'
    ];

    protected $casts = [
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function images()
    {
        return $this->hasMany(AdImage::class);
    }

    public function cta()
    {
        return $this->hasOne(AdCta::class);
    }

    public function tracking()
    {
        return $this->hasOne(AdTracking::class);
    }

    public function toApiFormat()
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'image_variants' => $this->images->map(function ($image) {
                return [
                    'image_url' => $image->image_url,
                    'density' => (float) $image->density,
                    'width' => $image->width,
                    'height' => $image->height,
                    'file_size' => $image->file_size,
                ];
            }),
            'cta' => $this->cta ? [
                'text' => $this->cta->text,
                'target_url' => $this->cta->target_url,
                'type' => $this->cta->type,
                'position' => [
                    'x' => (float) $this->cta->position_x,
                    'y' => (float) $this->cta->position_y,
                    'alignment' => $this->cta->alignment,
                ],
                'style' => $this->cta->style_json,
            ] : null,
            'tracking_urls' => $this->tracking ? [
                'impression_url' => $this->tracking->impression_url,
                'click_url' => $this->tracking->click_url,
                'pixels' => $this->tracking->pixels,
            ] : [],
            'priority' => $this->priority,
            'start_date' => $this->start_date?->toIso8601String(),
            'end_date' => $this->end_date?->toIso8601String(),
            'target' => $this->target,
            'metadata' => $this->metadata ?? [],
        ];
    }
}
```

### Routes

```php
Route::prefix('v1')->group(function () {
    // Public endpoints
    Route::get('/ads/active', [AdController::class, 'getActive']);
    
    // Tracking endpoints (can be public or authenticated based on requirements)
    Route::post('/ads/track/impression', [AdController::class, 'trackImpression']);
    Route::post('/ads/track/click', [AdController::class, 'trackClick']);
});
```

## Testing the Implementation

### 1. Create a Test Ad

```bash
curl -X POST http://localhost:8000/api/admin/ads \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-ad-001",
    "name": "Test Ad",
    "placement": "home_banner",
    "priority": 10,
    "images": [
      {
        "image_url": "https://via.placeholder.com/800x400",
        "density": 1.0,
        "width": 800,
        "height": 400
      }
    ],
    "cta": {
      "text": "Learn More",
      "target_url": "/explore-screen",
      "type": "internal",
      "position_x": 0.1,
      "position_y": 0.85
    }
  }'
```

### 2. Test Fetching Ads

```bash
curl http://localhost:8000/api/v1/ads/active?placement=home_banner&limit=5
```

### 3. Test Tracking

```bash
# Track impression
curl -X POST http://localhost:8000/api/v1/ads/track/impression \
  -H "Content-Type: application/json" \
  -d '{
    "ad_id": "test-ad-001",
    "timestamp": "2025-01-08T20:30:00.000Z",
    "type": "impression"
  }'

# Track click
curl -X POST http://localhost:8000/api/v1/ads/track/click \
  -H "Content-Type: application/json" \
  -d '{
    "ad_id": "test-ad-001",
    "timestamp": "2025-01-08T20:30:15.000Z",
    "type": "click"
  }'
```

## Performance Optimization Tips

1. **Add Database Indexes**:
   ```sql
   CREATE INDEX idx_ads_active ON ads(is_active, start_date, end_date, priority);
   CREATE INDEX idx_ads_placement ON ads(placement, is_active);
   ```

2. **Enable Query Caching**:
   ```php
   $ads = Cache::remember("ads_{$placement}", 900, function () use ($query) {
       return $query->get();
   });
   ```

3. **Use CDN for Images**: Host ad images on a CDN for fast global delivery

4. **Optimize Tracking**: Consider using a queue for tracking events to avoid blocking:
   ```php
   TrackAdEvent::dispatch($adId, $eventType, $timestamp);
   ```

## Next Steps

1. Implement the three endpoints above
2. Set up database tables and migrations
3. Create admin interface for managing ads
4. Test with the Flutter app
5. Monitor performance and tracking accuracy

For complete documentation, see `AD_SYSTEM.md`.
