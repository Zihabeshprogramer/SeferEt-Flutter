import 'package:flutter/material.dart';

/// Custom clipper for ticket shape with side notches
class TicketShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchRadius = 12.0;
    const notchMargin = 8.0;
    final notchY = size.height * 0.65;

    // Start at top left
    path.lineTo(0, notchY - notchRadius - notchMargin);

    // Left notch (concave circle)
    path.arcToPoint(
      Offset(0, notchY + notchRadius + notchMargin),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Bottom left corner
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);

    // Right notch (concave circle)
    path.lineTo(size.width, notchY + notchRadius + notchMargin);
    path.arcToPoint(
      Offset(size.width, notchY - notchRadius - notchMargin),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Top right corner
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Dashed separator widget
class DashedSeparator extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedSeparator({
    super.key,
    this.height = 1,
    this.color = const Color(0xFFE5E7EB),
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: DashedLinePainter(
          color: color,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
        ),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

/// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for flight path line
class FlightPathPainter extends CustomPainter {
  final Color lineColor;

  FlightPathPainter({this.lineColor = const Color(0xFFE5E7EB)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
