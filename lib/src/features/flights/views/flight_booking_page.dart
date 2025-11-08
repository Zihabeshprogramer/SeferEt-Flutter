import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../models/flight_models.dart';
import '../../../services/api_service.dart';
import '../../../../services/amadeus_flight_service.dart';
import '../widgets/flight_widgets.dart';
import 'flight_payment_page.dart';

/// Flight booking page with passenger information collection
/// Redesigned to match reference payment screen design language
class FlightBookingPage extends StatefulWidget {
  final FlightOffer offer;
  final int passengers;

  const FlightBookingPage({
    super.key,
    required this.offer,
    required this.passengers,
  });

  @override
  State<FlightBookingPage> createState() => _FlightBookingPageState();
}

class _FlightBookingPageState extends State<FlightBookingPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late final AmadeusFlightService _flightService;
  final _formKey = GlobalKey<FormState>();

  List<PassengerFormData> _passengerData = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  // Animation controller for flight path
  late AnimationController _animationController;
  late Animation<double> _planeAnimation;

  @override
  void initState() {
    super.initState();
    _flightService = AmadeusFlightService(
      baseUrl: 'http://172.20.10.9:8000',
    );
    _initializePassengerData();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _planeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // Animate to destination
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation when card is built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializePassengerData() {
    _passengerData = List.generate(
      widget.passengers,
      (index) => PassengerFormData(id: (index + 1).toString()),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final token = _apiService.authToken ?? '';
      int? customerId;
      
      // Try to get user info if authenticated
      if (token.isNotEmpty) {
        final user = await _apiService.getCurrentUser();
        if (user.success && user.data != null) {
          customerId = user.data!.id;
        }
      }

      final travelers = _passengerData.map((p) => p.toTravelerJson()).toList();
      
      // Get guest info from first passenger if no customer ID
      String? guestEmail;
      String? guestName;
      if (customerId == null && travelers.isNotEmpty) {
        final firstTraveler = travelers[0];
        guestEmail = firstTraveler['contact']['emailAddress'];
        guestName = '${firstTraveler['name']['firstName']} ${firstTraveler['name']['lastName']}';
      }

      // Proceed with backend booking (works for both authenticated and guest)
      final result = await _flightService.bookFlight(
        offer: widget.offer.toJson(),
        travelers: travelers,
        customerId: customerId,
        guestEmail: guestEmail,
        guestName: guestName,
        token: token,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        final bookingData = result['data'] as Map<String, dynamic>;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FlightPaymentPage(
              offer: widget.offer,
              bookingData: bookingData,
              passengers: widget.passengers,
            ),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Booking failed');
      }
    } catch (e) {
      String errorMessage = 'Booking failed';
      
      // Try to extract meaningful error from DioException
      if (e.toString().contains('DioException')) {
        errorMessage = 'Unable to process booking. Please check your information and try again.';
      } else {
        errorMessage = e.toString();
      }
      
      if (!mounted) return;
      setState(() {
        _errorMessage = errorMessage;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstSegment = widget.offer.itineraries.first.segments.first;
    final lastSegment = widget.offer.itineraries.first.segments.last;
    final totalPrice = widget.offer.price.total * widget.passengers;

    return Scaffold(
      body: Column(
        children: [
          // Blue header section with ticket (fixed, non-scrolling)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.primaryGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppColors.backgroundColor),
                          ),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textColor,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Flight Booking',
                              style: TextStyle(
                                color: AppColors.textTitleColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  // Flight Summary Card (fixed in blue section)
                  _buildFlightSummaryCard(firstSegment, lastSegment, totalPrice),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Scrollable form content
          Expanded(
            child: Container(
              color: AppColors.backgroundColor,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // White body container with form
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blackTransparent.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Passenger Information
                              ..._buildPassengerSections(),
                              // Error message
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.errorColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.errorColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.errorColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // Space for fixed button
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fixed bottom button
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildFlightSummaryCard(
    FlightSegment firstSegment,
    FlightSegment lastSegment,
    double totalPrice,
  ) {
    final duration = _formatDuration(widget.offer.itineraries.first.duration);
    final departureTime = _formatTime(firstSegment.departureTime);
    final arrivalTime = _formatTime(lastSegment.arrivalTime);
    final departureDate = _formatDate(firstSegment.departureTime);
    final arrivalDate = _formatDate(lastSegment.arrivalTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 170,
      child: ClipPath(
        clipper: TicketShapeClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackTransparent.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // Origin and Destination labels with codes
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Origin
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Origin',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.fadedTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstSegment.departure,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 15,),
                    // Animated curved flight path with plane icon and duration
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedBuilder(
                              animation: _planeAnimation,
                              builder: (context, child) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Curved dashed line
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      height: 50,
                                      child: CustomPaint(
                                        painter: CurvedFlightPathPainter(
                                          lineColor: const Color(0xFFD1D5DB),
                                          planeColor: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                    // Duration text in middle of curve
                                    Positioned(
                                      left: constraints.maxWidth / 2 - 30,
                                      bottom: 10,
                                      child: Text(
                                        duration,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Animated plane icon
                                    Positioned(
                                      left: _calculatePlaneX(_planeAnimation.value, constraints.maxWidth),
                                      top: _calculatePlaneY(_planeAnimation.value),
                                      child: Transform.rotate(
                                        angle: _calculatePlaneAngle(_planeAnimation.value),
                                        child: Icon(
                                          Icons.flight,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    // Destination
                    SizedBox(width: 15,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.fadedTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastSegment.arrival,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Flight times
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$departureDate – $departureTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '$arrivalDate – $arrivalTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const DashedSeparator(),
                const SizedBox(height: 12),
                // Airline and Price
                Row(
                  children: [
                    // Airline logo placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.flight,
                        color: AppColors.primaryColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      firstSegment.carrierCode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'USD ${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0061FF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDate(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  String _formatDuration(String isoDuration) {
    final hours = RegExp(r'(\d+)H').firstMatch(isoDuration)?.group(1) ?? '0';
    final minutes = RegExp(r'(\d+)M').firstMatch(isoDuration)?.group(1) ?? '0';
    return '${hours}h ${minutes}m';
  }

  // Calculate plane X position based on animation progress
  double _calculatePlaneX(double progress, double availableWidth) {
    const horizontalPadding = 8.0;
    final curveWidth = availableWidth - (horizontalPadding * 2);
    return (progress * curveWidth) + horizontalPadding - 10; // Center the icon on curve
  }

  // Calculate plane Y position along the curve
  double _calculatePlaneY(double progress) {
    final t = progress;
    // Quadratic curve (upward arc): y = size.height/2 + 4h * t * (t - 1)
    final y = 25 + 4 * 25 * t * (t - 1); // 25 = 50/2 (half of container height)
    return y - 10; // Adjust to center icon on curve
  }

  // Calculate plane rotation angle (tangent to curve)
  double _calculatePlaneAngle(double progress) {
    // Icon default orientation seems to be upward, so we need to rotate it
    // Keep plane facing right for 90% of journey
    if (progress < 0.9) {
      return 1.57; // 90 degrees clockwise to face right
    }
    // In last 10%, rotate from right back to upward
    final endProgress = (progress - 0.9) / 0.1; // 0 to 1 in last segment
    return 1.57 * (1.0 - endProgress); // Rotate from 90° back to 0° (upward)
  }

  List<Widget> _buildPassengerSections() {
    List<Widget> sections = [];

    for (int i = 0; i < _passengerData.length; i++) {
      if (i > 0) {
        sections.add(const SizedBox(height: 20));
        sections.add(Divider(color: AppColors.dividerColor));
        sections.add(const SizedBox(height: 20));
      }

      sections.add(
        Text(
          i == 0 ? 'Passenger Details' : 'Passenger ${i + 1}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
      );
      sections.add(const SizedBox(height: 16));
      sections.addAll(_buildPassengerForm(i, _passengerData[i]));
    }

    return sections;
  }

  List<Widget> _buildPassengerForm(int index, PassengerFormData data) {
    List<Widget> widgets = [];

    // Full Name
    widgets.add(
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Full Name',
          hintText: 'Enter full name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.secondaryColor, width: 2),
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        onSaved: (value) {
          final parts = value?.trim().split(' ') ?? [];
          data.firstName = parts.isNotEmpty ? parts.first.toUpperCase() : '';
          data.lastName = parts.length > 1 ? parts.sublist(1).join(' ').toUpperCase() : data.firstName;
        },
      ),
    );
    widgets.add(const SizedBox(height: 12));

    // Gender
    widgets.add(
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
        ),
        items: const [
          DropdownMenuItem(value: 'MALE', child: Text('Male')),
          DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
        ],
        validator: (value) => value == null ? 'Required' : null,
        onChanged: (value) => data.gender = value ?? 'MALE',
        onSaved: (value) => data.gender = value ?? 'MALE',
      ),
    );
    widgets.add(const SizedBox(height: 12));

    // Date of Birth
    widgets.add(
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          hintText: 'YYYY-MM-DD',
          suffixIcon: Icon(Icons.calendar_today, size: 20, color: AppColors.iconColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          try {
            DateTime.parse(value!);
            return null;
          } catch (e) {
            return 'Invalid date';
          }
        },
        onSaved: (value) => data.dateOfBirth = value?.trim() ?? '',
      ),
    );
    widgets.add(const SizedBox(height: 12));

    // Passport Number
    widgets.add(
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Passport Number',
          hintText: 'Enter passport number',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        onSaved: (value) {}, // Not stored in current model
      ),
    );
    widgets.add(const SizedBox(height: 12));

    // Nationality
    widgets.add(
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Nationality',
          hintText: 'Enter nationality',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        onSaved: (value) {}, // Not stored in current model
      ),
    );

    // Contact Information (only for first passenger)
    if (index == 0) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(
        Text(
          'Contact Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));

      // Email
      widgets.add(
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter email',
            prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.iconColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Invalid email';
            }
            return null;
          },
          onSaved: (value) => data.email = value?.trim() ?? '',
        ),
      );
      widgets.add(const SizedBox(height: 12));

      // Phone
      widgets.add(
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.iconColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onSaved: (value) => data.phone = value?.trim() ?? '',
        ),
      );

      // Additional Notes
      widgets.add(const SizedBox(height: 24));
      widgets.add(
        Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Any special requests...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
          ),
          maxLines: 4,
          onSaved: (value) {}, // Handle special requests
        ),
      );
    }

    return widgets;
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _isSubmitting ? null : _submitBooking,
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textTitleColor),
                    ),
                  )
                : Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      color: AppColors.textTitleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Helper class to store passenger form data
class PassengerFormData {
  final String id;
  String firstName = '';
  String lastName = '';
  String gender = 'MALE';
  String dateOfBirth = '';
  String email = '';
  String phone = '';

  PassengerFormData({required this.id});

  Map<String, dynamic> toTravelerJson() {
    return {
      'id': id,
      'dateOfBirth': dateOfBirth,
      'name': {
        'firstName': firstName,
        'lastName': lastName,
      },
      'gender': gender,
      'contact': {
        'emailAddress': email.isNotEmpty ? email : 'noreply@example.com',
        'phones': [
          {
            'deviceType': 'MOBILE',
            'countryCallingCode': '1',
            'number': phone.isNotEmpty ? phone.replaceAll(RegExp(r'[^\d]'), '') : '0000000000',
          }
        ],
      },
    };
  }
}

/// Custom painter for curved flight path with endpoint dots
class CurvedFlightPathPainter extends CustomPainter {
  final Color lineColor;
  final Color planeColor;

  CurvedFlightPathPainter({
    required this.lineColor,
    required this.planeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw curved dashed line
    _drawCurvedDashedLine(canvas, size);

    // Draw fixed endpoint dots
    _drawEndpointDots(canvas, size);
  }

  void _drawEndpointDots(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = planeColor
      ..style = PaintingStyle.fill;

    const dotRadius = 4.0;
    const horizontalPadding = 8.0;

    // Origin dot (left side, y at center)
    final originY = size.height / 2;
    canvas.drawCircle(Offset(horizontalPadding, originY), dotRadius, dotPaint);

    // Destination dot (right side, y at center)
    final destY = size.height / 2;
    canvas.drawCircle(Offset(size.width - horizontalPadding, destY), dotRadius, dotPaint);
  }

  void _drawCurvedDashedLine(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    const horizontalPadding = 8.0;
    final curveHeight = size.height / 2;
    final curveWidth = size.width - (horizontalPadding * 2);

    // Draw dashed curved line
    for (double i = 0; i < curveWidth; i += dashWidth + dashSpace) {
      final path = Path();
      final startX = i + horizontalPadding;
      final endX = (i + dashWidth > curveWidth) ? curveWidth + horizontalPadding : i + dashWidth + horizontalPadding;
      
      // Calculate Y positions using parabolic curve (upward arc)
      final t1 = i / curveWidth;
      final t2 = (endX - horizontalPadding) / curveWidth;
      
      final startY = size.height / 2 + curveHeight * 4 * t1 * (t1 - 1);
      final endY = size.height / 2 + curveHeight * 4 * t2 * (t2 - 1);
      
      path.moveTo(startX, startY);
      path.lineTo(endX, endY);
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CurvedFlightPathPainter oldDelegate) {
    return false; // Static curve and dots, no need to repaint
  }
}
