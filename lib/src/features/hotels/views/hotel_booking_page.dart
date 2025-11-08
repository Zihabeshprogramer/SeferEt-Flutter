import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../models/hotel_models.dart';
import '../../../providers/hotel_provider.dart';

class HotelBookingPage extends StatefulWidget {
  final Hotel hotel;
  final HotelOffer offer;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const HotelBookingPage({
    super.key,
    required this.hotel,
    required this.offer,
    this.checkIn,
    this.checkOut,
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> _guestControllers = [];
  final TextEditingController _specialRequestsController = TextEditingController();
  
  late DateTime _checkInDate;
  late DateTime _checkOutDate;

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.checkIn ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.checkOut ?? _checkInDate.add(const Duration(days: 2));
    
    // Initialize guest form controllers
    for (int i = 0; i < widget.offer.guests; i++) {
      _guestControllers.add({
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'email': TextEditingController(),
        'phone': TextEditingController(),
      });
    }
  }

  @override
  void dispose() {
    for (var controllers in _guestControllers) {
      controllers.values.forEach((controller) => controller.dispose());
    }
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Booking'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          if (provider.isBooking) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text('Processing your booking...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookingSummary(),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildDateSelection(),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildGuestInformation(),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildSpecialRequests(),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildPriceSummary(),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildBookingButton(),
                  const SizedBox(height: AppTheme.spacingXLarge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotel.name,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < widget.hotel.rating ? Icons.star : Icons.star_border,
                          color: AppColors.warningColor,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (widget.hotel.isAmadeus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: AppTheme.spacingXSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    'Amadeus',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          const Divider(),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            widget.offer.roomType,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.offer.bedType != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.offer.bedType!,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightgrayBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Dates',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Check-in',
                  date: _checkInDate,
                  onTap: () => _selectCheckInDate(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildDateField(
                  label: 'Check-out',
                  date: _checkOutDate,
                  onTap: () => _selectCheckOutDate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            '${_checkOutDate.difference(_checkInDate).inDays} night${_checkOutDate.difference(_checkInDate).inDays > 1 ? 's' : ''}',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guest Information',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        ..._guestControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return _buildGuestForm(index + 1, controllers);
        }).toList(),
      ],
    );
  }

  Widget _buildGuestForm(int guestNumber, Map<String, TextEditingController> controllers) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.lightgrayBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guest $guestNumber',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers['firstName'],
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: TextFormField(
                  controller: controllers['lastName'],
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (guestNumber == 1) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            TextFormField(
              controller: controllers['email'],
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                filled: true,
                fillColor: AppColors.backgroundColor,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            TextFormField(
              controller: controllers['phone'],
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                filled: true,
                fillColor: AppColors.backgroundColor,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Requests',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Optional - Let the hotel know if you have any special requirements',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        TextFormField(
          controller: _specialRequestsController,
          decoration: InputDecoration(
            hintText: 'E.g., early check-in, high floor, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            filled: true,
            fillColor: AppColors.lightgrayBackground,
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    final totalPrice = widget.offer.price * nights;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.offer.currency} ${widget.offer.price.toStringAsFixed(2)} × $nights night${nights > 1 ? 's' : ''}',
                style: AppTheme.bodyMedium,
              ),
              Text(
                '${widget.offer.currency} ${totalPrice.toStringAsFixed(2)}',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          const Divider(),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.offer.currency} ${totalPrice.toStringAsFixed(2)}',
                style: AppTheme.titleLarge.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
        ),
        child: Text(
          'Confirm Booking',
          style: AppTheme.buttonText.copyWith(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate.add(const Duration(days: 1)))) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Build guest list
    final guests = _guestControllers.map((controllers) {
      return BookingGuest(
        firstName: controllers['firstName']!.text,
        lastName: controllers['lastName']!.text,
        email: controllers['email']!.text.isNotEmpty ? controllers['email']!.text : null,
        phone: controllers['phone']!.text.isNotEmpty ? controllers['phone']!.text : null,
      );
    }).toList();

    // Calculate total price
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    final totalPrice = widget.offer.price * nights;

    // Create booking
    final booking = HotelBooking(
      hotelId: widget.hotel.id,
      offerId: widget.offer.id,
      checkIn: _checkInDate,
      checkOut: _checkOutDate,
      guests: guests,
      specialRequests: _specialRequestsController.text.isNotEmpty 
          ? _specialRequestsController.text 
          : null,
      totalPrice: totalPrice,
      currency: widget.offer.currency,
    );

    // Submit booking
    final provider = context.read<HotelProvider>();
    final success = await provider.bookHotel(booking);

    if (!mounted) return;

    if (success) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.successColor),
              const SizedBox(width: AppTheme.spacingSmall),
              const Text('Booking Confirmed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your hotel booking has been confirmed.'),
              if (provider.confirmedBooking?.confirmationNumber != null) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Confirmation #: ${provider.confirmedBooking!.confirmationNumber}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                'A confirmation email has been sent to ${guests.first.email}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.fadedTextColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.bookingError ?? 'Failed to book hotel'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}
