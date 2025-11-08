# Hotel Module - Quick Start Guide

## For Developers

### Running the Hotel Module

1. **Ensure all dependencies are installed:**
   ```bash
   flutter pub get
   ```

2. **Navigate to hotel search from the app:**
   ```dart
   Navigator.pushNamed(context, '/hotel-search');
   ```

3. **Or with search parameters:**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => HotelListPage(
         cityCode: 'LON',
         checkIn: DateTime(2025, 12, 1),
         checkOut: DateTime(2025, 12, 5),
         adults: 2,
         rooms: 1,
       ),
     ),
   );
   ```

### API Configuration

The hotel module uses the existing API configuration in `lib/src/constants/app_constants.dart`:

```dart
static String get baseUrl => 'http://172.20.10.9:8000/api/v1';
```

Make sure your Laravel backend is running on this URL or update it accordingly.

### Files to Know

**Core Implementation:**
- `lib/src/models/hotel_models.dart` - Data models
- `lib/src/services/hotel_service.dart` - API calls
- `lib/src/providers/hotel_provider.dart` - State management

**UI Pages:**
- `lib/src/views/hotel_list_page.dart` - Search & results
- `lib/src/views/hotel_detail_page.dart` - Hotel details
- `lib/src/views/hotel_booking_page.dart` - Booking form

### Using the Provider

The HotelProvider is already added to the app. Access it like this:

```dart
// In any widget
final provider = context.read<HotelProvider>();

// Search hotels
await provider.searchHotels(searchParams);

// Get hotel details
await provider.getHotelDetails('hotel_id');

// Book hotel
await provider.bookHotel(booking);

// Apply filters
provider.updateFilters(sourceFilter: 'local');

// Sort results
provider.updateSort('price');
```

### Common Operations

**1. Search for Hotels:**
```dart
final params = HotelSearchParams(
  cityCode: 'NYC',
  checkIn: DateTime.now().add(Duration(days: 7)),
  checkOut: DateTime.now().add(Duration(days: 10)),
  adults: 2,
  rooms: 1,
);

await context.read<HotelProvider>().searchHotels(params);
```

**2. Filter Local Hotels Only:**
```dart
context.read<HotelProvider>().updateFilters(sourceFilter: 'local');
```

**3. Navigate to Hotel Details:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HotelDetailPage(
      hotelId: hotel.id,
      hotel: hotel, // Optional: pass if already loaded
    ),
  ),
);
```

**4. Book a Hotel:**
```dart
final booking = HotelBooking(
  hotelId: hotel.id,
  offerId: offer.id,
  checkIn: checkInDate,
  checkOut: checkOutDate,
  guests: [
    BookingGuest(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: '+1234567890',
    ),
  ],
  totalPrice: totalPrice,
  currency: 'USD',
);

final success = await context.read<HotelProvider>().bookHotel(booking);
```

## For Backend Developers

### Required API Endpoints

#### 1. Search Hotels
**Endpoint:** `GET /api/v1/hotels/search`

**Query Parameters:**
- `city_code` (required): City code or name
- `check_in` (required): YYYY-MM-DD format
- `check_out` (required): YYYY-MM-DD format
- `adults` (required): Number of adults
- `rooms` (required): Number of rooms
- `min_price` (optional): Minimum price filter
- `max_price` (optional): Maximum price filter
- `min_rating` (optional): Minimum star rating
- `source` (optional): Filter by source (local/amadeus)

**Response Format:**
```json
{
  "success": true,
  "message": "Hotels found",
  "data": {
    "hotels": [
      {
        "id": "1",
        "name": "Grand Hotel",
        "description": "Luxury hotel description",
        "city_code": "LON",
        "city_name": "London",
        "address": "123 Main St",
        "latitude": 51.5074,
        "longitude": -0.1278,
        "rating": 5,
        "guest_rating": 4.5,
        "review_count": 250,
        "amenities": ["WiFi", "Pool", "Spa", "Gym"],
        "image_url": "https://example.com/hotel.jpg",
        "source": "local",
        "distance": 2.5,
        "distance_unit": "km",
        "offers": [
          {
            "id": "offer_1",
            "hotel_id": "1",
            "room_type": "Deluxe Room",
            "bed_type": "King Bed",
            "description": "Spacious room with city view",
            "price": 150.00,
            "currency": "USD",
            "guests": 2,
            "cancellable": true,
            "cancellation_deadline": "2025-11-30",
            "breakfast_included": true,
            "room_amenities": ["WiFi", "TV", "Mini Bar"]
          }
        ]
      }
    ]
  }
}
```

**Important:**
- Must return local hotels first, then Amadeus hotels
- Each hotel must have a `source` field ("local" or "amadeus")

#### 2. Get Hotel Details
**Endpoint:** `GET /api/v1/hotels/{id}`

**Response:** Same structure as a single hotel in search results

#### 3. Book Hotel
**Endpoint:** `POST /api/v1/hotels/book`

**Request Body:**
```json
{
  "hotel_id": "1",
  "offer_id": "offer_1",
  "check_in": "2025-12-01",
  "check_out": "2025-12-05",
  "guests": [
    {
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "phone": "+1234567890"
    }
  ],
  "special_requests": "Early check-in requested",
  "total_price": 600.00,
  "currency": "USD"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking confirmed",
  "data": {
    "booking": {
      "id": "booking_123",
      "hotel_id": "1",
      "offer_id": "offer_1",
      "check_in": "2025-12-01",
      "check_out": "2025-12-05",
      "guests": [...],
      "total_price": 600.00,
      "currency": "USD",
      "status": "confirmed",
      "confirmation_number": "CONF123456"
    }
  }
}
```

### Error Handling

All endpoints should return errors in this format:
```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "field_name": ["Error description"]
  },
  "statusCode": 400
}
```

## Testing

### Manual Testing Steps

1. **Launch the app:**
   ```bash
   flutter run
   ```

2. **Navigate to Hotels:**
   - From home screen, tap on Hotels section
   - Or navigate to `/hotel-search` route

3. **Test Search:**
   - Enter city name (e.g., "London")
   - Select check-in/check-out dates
   - Set adults and rooms count
   - Tap "Search Hotels"
   - Verify local hotels appear first
   - Verify Amadeus hotels have badges

4. **Test Filters:**
   - Tap filter icon
   - Filter by "Local Providers"
   - Verify only local hotels show
   - Clear filters

5. **Test Sorting:**
   - Sort by Price
   - Sort by Rating
   - Sort by Distance

6. **Test Hotel Details:**
   - Tap on a hotel card
   - Verify all information loads
   - Check Amadeus badge for Amadeus hotels
   - View room offers

7. **Test Booking:**
   - Select a room from details page
   - Fill in guest information
   - Review price summary
   - Submit booking
   - Verify confirmation dialog

### Common Issues & Solutions

**Issue: No hotels found**
- Check backend is running
- Verify API endpoint URL in app_constants.dart
- Check backend logs for errors
- Ensure test data exists in backend

**Issue: Images not loading**
- Verify image URLs are valid and accessible
- Check network permissions in AndroidManifest.xml / Info.plist
- Test image URL in browser

**Issue: Booking fails**
- Check backend logs for detailed error
- Verify all required fields are sent
- Check authentication token is valid

**Issue: Local hotels not appearing first**
- Verify backend returns `source: "local"` for local hotels
- Check HotelService.searchHotels() sorting logic

## Production Checklist

Before deploying to production:

- [ ] Update API base URL in app_constants.dart
- [ ] Test with production backend
- [ ] Verify all images load correctly
- [ ] Test booking flow end-to-end
- [ ] Verify email confirmations are sent
- [ ] Test error scenarios
- [ ] Check loading states
- [ ] Verify Amadeus attribution is visible
- [ ] Test on multiple devices/screen sizes
- [ ] Verify payment integration (if applicable)
- [ ] Test offline behavior
- [ ] Check app permissions are configured

## Support

For help:
1. Check HOTEL_MODULE_IMPLEMENTATION.md for detailed documentation
2. Review existing code in similar modules (flights, packages)
3. Check Laravel backend API documentation
4. Contact the development team

## Quick Reference

**Navigate to hotel search:**
```dart
Navigator.pushNamed(context, '/hotel-search');
```

**Access provider:**
```dart
context.read<HotelProvider>()
context.watch<HotelProvider>()
```

**Key classes:**
- `Hotel` - Hotel data model
- `HotelOffer` - Room offer model
- `HotelBooking` - Booking model
- `HotelProvider` - State management
- `HotelService` - API calls

**API Base URL:**
```dart
AppConstants.baseUrl // = 'http://172.20.10.9:8000/api/v1'
```
