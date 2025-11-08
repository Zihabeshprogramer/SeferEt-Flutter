import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../models/flight_models.dart';
import '../services/api_service.dart';
import '../../services/amadeus_flight_service.dart';

/// My Bookings page - displays user's flight bookings
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late final AmadeusFlightService _flightService;
  late TabController _tabController;

  List<FlightBooking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _flightService = AmadeusFlightService(
      baseUrl: 'http://172.20.10.9:8000',
    );
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _apiService.authToken ?? '';
      final result = await _flightService.getMyBookings(token: token);

      setState(() {
        _bookings = result.map((e) => FlightBooking.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load bookings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<FlightBooking> get _upcomingBookings {
    return _bookings.where((b) => !b.isCancelled && b.isConfirmed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<FlightBooking> get _pastBookings {
    return _bookings.where((b) => b.isCancelled || b.status == 'completed').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          indicatorWeight: 3,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.fadedTextColor,
          labelStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.bodyMedium,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(_upcomingBookings, isUpcoming: true),
                    _buildBookingsList(_pastBookings, isUpcoming: false),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Error Loading Bookings',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.fadedTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: _fetchBookings,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<FlightBooking> bookings, {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flight_takeoff,
                size: 64,
                color: AppColors.fadedTextColor.withOpacity(0.5),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                isUpcoming ? 'No Upcoming Bookings' : 'No Past Bookings',
                style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                isUpcoming ? 'Book your next flight adventure!' : 'Your booking history will appear here',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.fadedTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(bookings[index], isUpcoming: isUpcoming),
      ),
    );
  }

  Widget _buildBookingCard(FlightBooking booking, {required bool isUpcoming}) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PNR: ${booking.pnr ?? 'N/A'}',
                        style: AppTheme.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${booking.bookingReference}',
                        style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: AppTheme.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppTheme.spacingMedium),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.fadedTextColor),
                const SizedBox(width: 4),
                Text(
                  booking.passengerName,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: AppColors.fadedTextColor),
                const SizedBox(width: 4),
                Text(
                  '${booking.passengers} passenger${booking.passengers > 1 ? 's' : ''}',
                  style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                const Icon(Icons.airline_seat_recline_normal, size: 16, color: AppColors.fadedTextColor),
                const SizedBox(width: 4),
                Text(
                  booking.flightClass,
                  style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                ),
              ],
            ),
            const Divider(height: AppTheme.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                    Text(
                      '${booking.currency} ${booking.totalAmount.toStringAsFixed(2)}',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Payment Status',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                    Text(
                      _getPaymentStatusText(booking.paymentStatus),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: booking.isPaid ? AppColors.successColor : AppColors.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Booked on: ${DateFormat('MMM dd, yyyy').format(booking.createdAt)}',
              style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
            ),
            if (isUpcoming && !booking.isCancelled) ...[
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewBookingDetails(booking),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryColor),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorColor),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      case 'pending':
        return AppColors.warningColor;
      default:
        return AppColors.fadedTextColor;
    }
  }

  String _getStatusText(String status) {
    return status.toUpperCase();
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'partial':
        return 'Partial';
      case 'refunded':
        return 'Refunded';
      default:
        return status.toUpperCase();
    }
  }

  void _viewBookingDetails(FlightBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Text(
                'Booking Details',
                style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              _buildDetailRow('PNR', booking.pnr ?? 'N/A'),
              _buildDetailRow('Booking Reference', booking.bookingReference),
              _buildDetailRow('Passenger', booking.passengerName),
              _buildDetailRow('Email', booking.passengerEmail),
              if (booking.passengerPhone != null) 
                _buildDetailRow('Phone', booking.passengerPhone!),
              _buildDetailRow('Passengers', '${booking.passengers}'),
              _buildDetailRow('Class', booking.flightClass),
              _buildDetailRow('Total Amount', '${booking.currency} ${booking.totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Payment Status', _getPaymentStatusText(booking.paymentStatus)),
              _buildDetailRow('Booking Status', _getStatusText(booking.status)),
              _buildDetailRow('Booked On', DateFormat('MMM dd, yyyy HH:mm').format(booking.createdAt)),
              if (booking.specialRequests != null) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Special Requests',
                  style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.specialRequests!,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(FlightBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCancellation(booking);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancellation(FlightBooking booking) async {
    try {
      final token = _apiService.authToken ?? '';
      await _flightService.cancelBooking(
        bookingId: booking.id,
        reason: 'Cancelled by customer',
        token: token,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );

      _fetchBookings();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}
