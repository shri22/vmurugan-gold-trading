import 'package:flutter/material.dart';

class VMUruganLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;

  const VMUruganLogo({
    super.key,
    this.size = 60.0,
    this.primaryColor = Colors.red,
    this.secondaryColor = Colors.black,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: VMUruganLogoPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          textColor: textColor,
        ),
      ),
    );
  }
}

class VMUruganLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;

  VMUruganLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = secondaryColor;

    // Draw diamond shape background
    final diamondPath = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // Diamond points
    final top = Offset(center.dx, center.dy - radius);
    final right = Offset(center.dx + radius * 0.8, center.dy - radius * 0.2);
    final bottom = Offset(center.dx, center.dy + radius);
    final left = Offset(center.dx - radius * 0.8, center.dy - radius * 0.2);

    diamondPath.moveTo(top.dx, top.dy);
    diamondPath.lineTo(right.dx, right.dy);
    diamondPath.lineTo(bottom.dx, bottom.dy);
    diamondPath.lineTo(left.dx, left.dy);
    diamondPath.close();

    // Fill diamond with gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.grey.shade300,
        Colors.grey.shade100,
        Colors.white,
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);
    canvas.drawPath(diamondPath, paint);

    // Draw diamond outline
    canvas.drawPath(diamondPath, strokePaint);

    // Draw inner lines for diamond facets
    paint.shader = null;
    paint.color = secondaryColor.withOpacity(0.3);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;

    // Top facet lines
    canvas.drawLine(top, Offset(center.dx - radius * 0.3, center.dy - radius * 0.1), paint);
    canvas.drawLine(top, Offset(center.dx + radius * 0.3, center.dy - radius * 0.1), paint);
    canvas.drawLine(left, Offset(center.dx - radius * 0.3, center.dy - radius * 0.1), paint);
    canvas.drawLine(right, Offset(center.dx + radius * 0.3, center.dy - radius * 0.1), paint);

    // Bottom facet lines
    canvas.drawLine(bottom, Offset(center.dx - radius * 0.2, center.dy + radius * 0.3), paint);
    canvas.drawLine(bottom, Offset(center.dx + radius * 0.2, center.dy + radius * 0.3), paint);
    canvas.drawLine(bottom, center, paint);

    // Draw "Vm" text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'V',
            style: TextStyle(
              fontSize: size.width * 0.25,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily: 'Arial',
            ),
          ),
          TextSpan(
            text: 'm',
            style: TextStyle(
              fontSize: size.width * 0.25,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily: 'Arial',
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2 - radius * 0.1,
    );
    textPainter.paint(canvas, textOffset);

    // Add small decorative elements (representing hands/crown from original)
    paint.style = PaintingStyle.fill;
    paint.color = secondaryColor;

    // Top decorative elements
    final decorSize = size.width * 0.03;
    for (int i = 0; i < 5; i++) {
      final x = center.dx - decorSize * 2 + (decorSize * i);
      final y = center.dy - radius * 0.8;
      canvas.drawCircle(Offset(x, y), decorSize / 2, paint);
    }

    // Side decorative elements
    for (int i = 0; i < 3; i++) {
      final leftX = center.dx - radius * 0.6;
      final rightX = center.dx + radius * 0.6;
      final y = center.dy - radius * 0.4 + (decorSize * i * 1.5);
      canvas.drawCircle(Offset(leftX, y), decorSize / 3, paint);
      canvas.drawCircle(Offset(rightX, y), decorSize / 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative simple logo widget
class VMUruganSimpleLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color textColor;

  const VMUruganSimpleLogo({
    super.key,
    this.size = 60.0,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Vm',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }
}

// Logo for app bar (smaller version)
class VMUruganAppBarLogo extends StatelessWidget {
  const VMUruganAppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VMUruganSimpleLogo(
          size: 32,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        ),
        const SizedBox(width: 8),
        const Text(
          'VMUrugan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
