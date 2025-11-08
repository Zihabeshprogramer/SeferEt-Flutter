# Backend Setup for Hotels API

## Issue
The Flutter app is trying to call:
```
GET http://172.20.10.9:8000/api/v1/hotels/search
```

But this endpoint doesn't exist in your Laravel backend yet.

## Quick Setup Steps

### 1. Add Routes to Laravel
File: `SeferEt-Laravel/routes/api.php`

```php
// Hotel Routes (add to api.php)
Route::prefix('v1')->group(function () {
    // ... existing routes ...
    
    // Hotel endpoints
    Route::prefix('hotels')->group(function () {
        Route::get('search', [App\Http\Controllers\HotelController::class, 'search']);
        Route::get('{id}', [App\Http\Controllers\HotelController::class, 'show']);
        Route::post('book', [App\Http\Controllers\HotelController::class, 'book'])->middleware('auth:sanctum');
    });
});
```

### 2. Create HotelController
File: `SeferEt-Laravel/app/Http/Controllers/HotelController.php`

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class HotelController extends Controller
{
    public function search(Request $request)
    {
        // For now, return mock data
        // Later integrate with your local hotels DB and Amadeus API
        
        $cityCode = $request->input('city_code');
        $checkIn = $request->input('check_in');
        $checkOut = $request->input('check_out');
        $adults = $request->input('adults', 2);
        $rooms = $request->input('rooms', 1);
        
        // Mock hotel data
        $hotels = [
            [
                'id' => '1',
                'name' => 'Grand Hotel ' . $cityCode,
                'description' => 'Luxury 5-star hotel in the heart of the city',
                'city_code' => $cityCode,
                'city_name' => $this->getCityName($cityCode),
                'address' => '123 Main Street',
                'rating' => 5,
                'guest_rating' => 4.5,
                'review_count' => 250,
                'amenities' => ['WiFi', 'Pool', 'Spa', 'Gym', 'Restaurant'],
                'image_url' => 'https://via.placeholder.com/300x200',
                'source' => 'local',
                'distance' => 2.5,
                'distance_unit' => 'km',
                'offers' => [
                    [
                        'id' => 'offer_1',
                        'hotel_id' => '1',
                        'room_type' => 'Deluxe Room',
                        'bed_type' => 'King Bed',
                        'price' => 150.00,
                        'currency' => 'USD',
                        'guests' => $adults,
                        'cancellable' => true,
                        'breakfast_included' => true,
                    ]
                ]
            ],
            [
                'id' => '2',
                'name' => 'Business Plaza Hotel',
                'description' => 'Perfect for business travelers',
                'city_code' => $cityCode,
                'city_name' => $this->getCityName($cityCode),
                'address' => '456 Business District',
                'rating' => 4,
                'guest_rating' => 4.2,
                'review_count' => 180,
                'amenities' => ['WiFi', 'Business Center', 'Restaurant'],
                'image_url' => 'https://via.placeholder.com/300x200',
                'source' => 'local',
                'distance' => 1.8,
                'distance_unit' => 'km',
                'offers' => [
                    [
                        'id' => 'offer_2',
                        'hotel_id' => '2',
                        'room_type' => 'Standard Room',
                        'bed_type' => 'Queen Bed',
                        'price' => 95.00,
                        'currency' => 'USD',
                        'guests' => $adults,
                        'cancellable' => false,
                        'breakfast_included' => false,
                    ]
                ]
            ],
            [
                'id' => 'amadeus_3',
                'name' => 'Amadeus Partner Hotel',
                'description' => 'Hotel from Amadeus booking system',
                'city_code' => $cityCode,
                'city_name' => $this->getCityName($cityCode),
                'address' => '789 International Avenue',
                'rating' => 4,
                'guest_rating' => 4.4,
                'review_count' => 320,
                'amenities' => ['WiFi', 'Pool', 'Airport Shuttle'],
                'image_url' => 'https://via.placeholder.com/300x200',
                'source' => 'amadeus',
                'distance' => 3.2,
                'distance_unit' => 'km',
                'offers' => [
                    [
                        'id' => 'offer_3',
                        'hotel_id' => 'amadeus_3',
                        'room_type' => 'Superior Room',
                        'bed_type' => 'Twin Beds',
                        'price' => 120.00,
                        'currency' => 'USD',
                        'guests' => $adults,
                        'cancellable' => true,
                        'breakfast_included' => true,
                    ]
                ]
            ],
        ];
        
        return response()->json([
            'success' => true,
            'message' => 'Hotels found',
            'data' => [
                'hotels' => $hotels
            ]
        ]);
    }
    
    public function show($id)
    {
        // Return single hotel details
        $hotel = [
            'id' => $id,
            'name' => 'Hotel Details #' . $id,
            'description' => 'Full hotel description here',
            'city_code' => 'LON',
            'city_name' => 'London',
            'address' => '123 Main Street',
            'rating' => 5,
            'guest_rating' => 4.5,
            'review_count' => 250,
            'amenities' => ['WiFi', 'Pool', 'Spa', 'Gym', 'Restaurant'],
            'image_url' => 'https://via.placeholder.com/300x200',
            'source' => strpos($id, 'amadeus') !== false ? 'amadeus' : 'local',
            'distance' => 2.5,
            'distance_unit' => 'km',
            'offers' => [
                [
                    'id' => 'offer_1',
                    'hotel_id' => $id,
                    'room_type' => 'Deluxe Room',
                    'bed_type' => 'King Bed',
                    'description' => 'Spacious room with city view',
                    'price' => 150.00,
                    'currency' => 'USD',
                    'guests' => 2,
                    'cancellable' => true,
                    'cancellation_deadline' => now()->addDays(7)->format('Y-m-d'),
                    'breakfast_included' => true,
                    'room_amenities' => ['WiFi', 'TV', 'Mini Bar', 'Safe'],
                ]
            ]
        ];
        
        return response()->json([
            'success' => true,
            'message' => 'Hotel details retrieved',
            'data' => [
                'hotel' => $hotel
            ]
        ]);
    }
    
    public function book(Request $request)
    {
        $request->validate([
            'hotel_id' => 'required',
            'offer_id' => 'required',
            'check_in' => 'required|date',
            'check_out' => 'required|date',
            'guests' => 'required|array',
            'total_price' => 'required|numeric',
            'currency' => 'required|string',
        ]);
        
        // Mock booking response
        $booking = [
            'id' => 'booking_' . uniqid(),
            'hotel_id' => $request->hotel_id,
            'offer_id' => $request->offer_id,
            'check_in' => $request->check_in,
            'check_out' => $request->check_out,
            'guests' => $request->guests,
            'total_price' => $request->total_price,
            'currency' => $request->currency,
            'status' => 'confirmed',
            'confirmation_number' => 'CONF' . strtoupper(substr(md5(uniqid()), 0, 8)),
        ];
        
        return response()->json([
            'success' => true,
            'message' => 'Booking confirmed successfully',
            'data' => [
                'booking' => $booking
            ]
        ]);
    }
    
    private function getCityName($cityCode)
    {
        $cities = [
            'LON' => 'London',
            'NYC' => 'New York',
            'PAR' => 'Paris',
            'DXB' => 'Dubai',
            'TYO' => 'Tokyo',
            'JED' => 'Mecca',
            'ADD' => 'Addis Ababa',
        ];
        
        return $cities[$cityCode] ?? $cityCode;
    }
}
```

### 3. Test the Endpoint

After adding the route and controller:

```bash
# Restart your Laravel server
php artisan serve --host=172.20.10.9 --port=8000

# Test the endpoint
curl "http://172.20.10.9:8000/api/v1/hotels/search?city_code=LON&check_in=2025-12-01&check_out=2025-12-05&adults=2&rooms=1"
```

### 4. Hot Restart Flutter App

After the backend is ready:
1. Press 'R' in Flutter terminal to hot restart
2. Navigate to Hotels search
3. Search for a city
4. You should now see results!

## Next Steps

Once the mock data works, you can:
1. Connect to your local hotels database
2. Integrate Amadeus Hotels API
3. Implement the unified hotel search logic as per your requirements

## Troubleshooting

### "Connection refused"
- Make sure Laravel is running on `172.20.10.2:8000`
- Check your firewall settings
- Verify the IP address in `app_constants.dart`

### "401 Unauthorized"
- Some endpoints require authentication
- Make sure you're logged in the app
- Check the `auth:sanctum` middleware

### Still not working?
- Check Laravel logs: `tail -f storage/logs/laravel.log`
- Check Flutter console for error details
- Verify the route with `php artisan route:list | grep hotel`
