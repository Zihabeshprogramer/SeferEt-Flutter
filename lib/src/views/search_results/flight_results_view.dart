import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class FlightResultsView extends StatefulWidget {
  final String from;
  final String to;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int passengers;
  final String flightClass;
  final bool isRoundTrip;

  const FlightResultsView({
    super.key,
    required this.from,
    required this.to,
    this.departureDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
    required this.isRoundTrip,
  });

  @override
  State<FlightResultsView> createState() => _FlightResultsViewState();
}

class _FlightResultsViewState extends State<FlightResultsView> {
  String _sortBy = 'price';
  
  // Mock flight data
  final List<Map<String, dynamic>> _flights = [
    {
      'airline': 'Ethiopian Airlines',
      'logo': '🛫',
      'departure_time': '08:30',
      'arrival_time': '14:45',
      'duration': '6h 15m',
      'stops': 'Non-stop',
      'price': 850.00,
      'currency': 'USD',
    },
    {
      'airline': 'Emirates',
      'logo': '✈️',
      'departure_time': '10:15',
      'arrival_time': '16:30',
      'duration': '6h 15m',
      'stops': 'Non-stop',
      'price': 1200.00,
      'currency': 'USD',
    },
    {
      'airline': 'Turkish Airlines',
      'logo': '🛩️',
      'departure_time': '12:45',
      'arrival_time': '20:30',
      'duration': '7h 45m',
      'stops': '1 Stop',
      'price': 720.00,
      'currency': 'USD',
    },
    {
      'airline': 'Qatar Airways',
      'logo': '✈️',
      'departure_time': '22:10',
      'arrival_time': '06:25+1',
      'duration': '8h 15m',
      'stops': '1 Stop',
      'price': 950.00,
      'currency': 'USD',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Flight Results',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: AppColors.primaryColor),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              PopupMenuItem(value: 'duration', child: Text('Sort by Duration')),
              PopupMenuItem(value: 'departure', child: Text('Sort by Departure')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSummary(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: _flights.length,
              itemBuilder: (context, index) => _buildFlightCard(_flights[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
    final dateFormat = widget.departureDate != null
        ? '${widget.departureDate!.day}/${widget.departureDate!.month}'
        : '';
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: AppColors.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.from} → ${widget.to}',
                      style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.passengers} passenger${widget.passengers > 1 ? 's' : ''} • $dateFormat • ${widget.flightClass}',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                  ],
                ),
              ),
              if (widget.isRoundTrip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Round Trip',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  flight['logo'],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight['airline'],
                        style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        flight['stops'],
                        style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${flight['price'].toStringAsFixed(0)}',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per person',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight['departure_time'],
                      style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.from,
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.dividerColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flight['duration'],
                        style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      flight['arrival_time'],
                      style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.to,
                      style: AppTheme.bodySmall.copyWith(color: AppColors.fadedTextColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                ),
                onPressed: () => _selectFlight(flight),
                child: Text(
                  'Select Flight',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.backgroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectFlight(Map<String, dynamic> flight) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${flight['airline']} flight for \$${flight['price']}'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }
}
