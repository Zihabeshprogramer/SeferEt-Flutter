import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

class TicketCard extends StatelessWidget {
  final String departureDate;
  final String departureCode;
  final String arrivalDate;
  final String arrivalCode;
  final String departureTime;
  final String arrivalTime;
  final String airline;
  final double price;
  final String airlineLogo;

  const TicketCard({
    super.key,
    required this.departureDate,
    required this.departureCode,
    required this.arrivalDate,
    required this.arrivalCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.airline,
    required this.airlineLogo,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall + AppTheme.spacingXSmall),
      child: CustomPaint(
        painter: TicketCardPainter(),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTicketContent(context),
              const MySeparator(color: AppColors.fadedTextColor),
              const SizedBox(height: AppTheme.spacingMedium - AppTheme.spacingXSmall),
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailsBottomSheet(context),
      child: Column(
        children: [
          _buildFlightDetails(),
          const SizedBox(height: AppTheme.spacingSmall),
          _buildTimeDetails(),
          const SizedBox(height: AppTheme.spacingLarge),
        ],
      ),
    );
  }

  Widget _buildFlightDetails() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              departureDate,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXSmall),
            Text(
              departureCode,
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CustomPaint(
          size: const Size(120, 30),
          painter: FlightDurationPainter(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              arrivalDate,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXSmall),
            Text(
              arrivalCode,
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeDetails() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          departureTime,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
          ),
        ),
        Text(
          arrivalTime,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              airlineLogo,
              width: AppTheme.iconSizeMedium,
              height: AppTheme.iconSizeMedium,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              airline,
              style: AppTheme.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => _showFlightDetailBottomSheet(context),
          child: Text(
            "View Flight Details",
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 1.0,
          child: DetailsBottomSheet(
            departureDate: departureDate,
            departureCode: departureCode,
            arrivalDate: arrivalDate,
            arrivalCode: arrivalCode,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            airline: airline,
            airlineLogo: airlineLogo,
            price: price,
          ),
        );
      },
    );
  }

  void _showFlightDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      builder: (context) => _buildFlightDetailBottomSheet(),
    );
  }

  Widget _buildFlightDetailBottomSheet() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHandle(),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildAirlineSection(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildFlightInfoSection(),
            const Divider(),
            _buildPricingSection(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Container(
      width: 60,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.dividerColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
    );
  }

  Widget _buildAirlineSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.asset(
          airlineLogo,
          width: 50,
          height: 50,
        ),
        const SizedBox(width: AppTheme.spacingSmall + AppTheme.spacingXSmall),
        Text(
          airline,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFlightInfoSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.flight_takeoff),
          title: Text('Departure: $departureCode ($departureTime)'),
        ),
        ListTile(
          leading: const Icon(Icons.flight_land),
          title: Text('Arrival: $arrivalCode ($arrivalTime)'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('Travel Date: $departureDate to $arrivalDate'),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return ListTile(
      leading: const Icon(Icons.attach_money),
      title: Text('Price: \$${price.toStringAsFixed(2)}'),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
      ),
      child: Text(
        'Close',
        style: AppTheme.buttonText,
      ),
    );
  }
}

class TicketCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.backgroundColor
      ..style = PaintingStyle.fill;

    final roundedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(AppTheme.borderRadiusLarge),
    );
    canvas.drawRRect(roundedRect, paint);

    const cutoutRadius = 12.0;
    final leftCutoutCenter = Offset(0, size.height * 0.65);
    final rightCutoutCenter = Offset(size.width, size.height * 0.65);

    canvas.drawCircle(
      leftCutoutCenter,
      cutoutRadius,
      Paint()..color = AppColors.primaryColor,
    );
    canvas.drawCircle(
      rightCutoutCenter,
      cutoutRadius,
      Paint()..color = AppColors.primaryColor,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TicketListView extends StatelessWidget {
  const TicketListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
        children: const [
          TicketCard(
            departureDate: "Mon 20, Dec",
            departureCode: "USA",
            arrivalDate: "DPS",
            arrivalCode: "BALI",
            departureTime: "06:50 AM",
            arrivalTime: "11:20 AM",
            airline: "Air Asia",
            airlineLogo: 'assets/airasia.png',
            price: 421.56,
          ),
          TicketCard(
            departureDate: "Mon 20, Dec",
            departureCode: "USA",
            arrivalDate: "Tue 21, Dec",
            arrivalCode: "BALI",
            departureTime: "06:50 AM",
            arrivalTime: "11:20 AM",
            airline: "Air Asia",
            airlineLogo: 'assets/garuda.png',
            price: 421.56,
          ),
          TicketCard(
            departureDate: "Mon 20, Dec",
            departureCode: "USA",
            arrivalDate: "Tue 21, Dec",
            arrivalCode: "BALI",
            departureTime: "06:50 AM",
            arrivalTime: "11:20 AM",
            airline: "Air Asia",
            airlineLogo: 'assets/lionair.png',
            price: 421.56,
          ),
        ],
      ),
    );
  }
}

class MySeparator extends StatelessWidget {
  const MySeparator({
    super.key,
    this.height = 1,
    this.color = AppColors.textColor,
  });
  
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 10.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class FlightDurationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (double i = 0; i < size.width; i += 10) {
      path.moveTo(i, _curveY(i, size.width, size.height));
      path.lineTo(i + 5, _curveY(i + 5, size.width, size.height));
    }

    canvas.drawPath(path, paint);

    final startPoint = Offset(0, _curveY(0, size.width, size.height));
    final endPoint = Offset(size.width, _curveY(size.width, size.width, size.height));
    
    canvas.drawCircle(
      startPoint,
      4,
      Paint()..color = AppColors.primaryColor,
    );
    canvas.drawCircle(
      endPoint,
      4,
      Paint()..color = AppColors.primaryColor,
    );

    final icon = Icons.airplanemode_active.codePoint;
    final airplaneOffset = Offset(
      size.width / 2,
      _curveY(size.width / 2, size.width, size.height),
    );

    canvas.save();
    canvas.translate(airplaneOffset.dx, airplaneOffset.dy);
    canvas.rotate(1.6);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon),
        style: TextStyle(
          fontSize: 26,
          color: AppColors.primaryColor,
          fontFamily: Icons.airplanemode_active.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();

    const durationText = TextSpan(
      text: "1h 50m",
      style: TextStyle(
        color: AppColors.fadedTextColor,
        fontSize: 16,
      ),
    );
    final durationTextPainter = TextPainter(
      text: durationText,
      textDirection: TextDirection.ltr,
    );
    durationTextPainter.layout();
    durationTextPainter.paint(
      canvas,
      Offset(
        size.width / 2 - durationTextPainter.width / 2,
        _curveY(size.width / 2, size.width, size.height) + 20,
      ),
    );
  }

  double _curveY(double x, double width, double height) {
    final normalizedX = x / width * 2 - 1;
    final maxHeight = height;
    return maxHeight - 30 * (1 - normalizedX * normalizedX);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DetailsBottomSheet extends StatelessWidget {
  final String departureDate;
  final String departureCode;
  final String arrivalDate;
  final String arrivalCode;
  final String departureTime;
  final String arrivalTime;
  final String airline;
  final String airlineLogo;
  final double price;

  const DetailsBottomSheet({
    super.key,
    required this.departureDate,
    required this.departureCode,
    required this.arrivalDate,
    required this.arrivalCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.airline,
    required this.airlineLogo,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final fares = [
      {
        "type": "Economy Saver",
        "price": 150.00,
        "luggage": "15kg",
        "benefits": "Non-refundable, limited changes allowed"
      },
      {
        "type": "Economy Flex",
        "price": 200.00,
        "luggage": "25kg",
        "benefits": "Refundable, free changes allowed"
      },
      {
        "type": "Business Class",
        "price": 450.00,
        "luggage": "40kg",
        "benefits": "Refundable, lounge access included"
      },
    ];

    return Container(
      color: AppColors.backgroundColor,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Text(
            "$departureDate | $departureTime ➝ $arrivalDate | $arrivalTime",
            style: AppTheme.fadedText,
          ),
          const Divider(),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            "Select Fare Option",
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Expanded(
            child: ListView.builder(
              itemCount: fares.length,
              itemBuilder: (context, index) {
                final fare = fares[index];
                return FareCard(
                  type: fare["type"] as String,
                  price: fare["price"] as double,
                  luggage: fare["luggage"] as String,
                  benefits: fare["benefits"] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$departureCode ➝ $arrivalCode",
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class FareCard extends StatelessWidget {
  final String type;
  final double price;
  final String luggage;
  final String benefits;

  const FareCard({
    super.key,
    required this.type,
    required this.price,
    required this.luggage,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$type fare selected!")),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Luggage: $luggage",
                    style: AppTheme.fadedText,
                  ),
                  Text(
                    "\$${price.toStringAsFixed(2)}",
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                benefits,
                style: AppTheme.fadedText,
              ),
              const SizedBox(height: AppTheme.spacingMedium - AppTheme.spacingXSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/passenger-details");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                      ),
                      child: Text(
                        "Select",
                        style: AppTheme.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
