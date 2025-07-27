import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A simple color wheel widget for picking primary colors
class SimpleColorWheel extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final double size;

  const SimpleColorWheel({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.size = 200,
  });

  @override
  State<SimpleColorWheel> createState() => _SimpleColorWheelState();
}

class _SimpleColorWheelState extends State<SimpleColorWheel> {
  late Color _selectedColor;
  Offset? _currentOffset;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Color wheel
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ColorWheelPainter(),
            ),
          ),
          
          // Selection indicator
          if (_currentOffset != null)
            Positioned(
              left: _currentOffset!.dx - 8,
              top: _currentOffset!.dy - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _updateColor(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateColor(details.localPosition);
  }

  void _updateColor(Offset position) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2;
    
    // Calculate distance from center
    final distance = (position - center).distance;
    
    // Only update if within the circle
    if (distance <= radius) {
      // Calculate angle
      final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
      final hue = (angle * 180 / math.pi + 360) % 360;
      
      // Calculate saturation based on distance from center
      final saturation = math.min(distance / radius, 1.0);
      
      // Create color with full lightness and calculated hue/saturation
      final color = HSLColor.fromAHSL(1.0, hue, saturation, 0.5).toColor();
      
      setState(() {
        _selectedColor = color;
        _currentOffset = position;
      });
      
      widget.onColorChanged(color);
    }
  }
}

class _ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create gradient for color wheel
    final colors = <Color>[];
    final stops = <double>[];
    
    // Generate colors around the wheel
    for (int i = 0; i <= 360; i += 10) {
      colors.add(HSLColor.fromAHSL(1.0, i.toDouble(), 1.0, 0.5).toColor());
      stops.add(i / 360);
    }
    
    // Draw the color wheel using multiple sectors
    for (int i = 0; i < 36; i++) {
      final startAngle = (i * 10) * math.pi / 180;
      final endAngle = ((i + 1) * 10) * math.pi / 180;
      
      final gradient = RadialGradient(
        colors: [
          HSLColor.fromAHSL(1.0, i * 10.0, 0.0, 0.5).toColor(), // Center: white/gray
          HSLColor.fromAHSL(1.0, i * 10.0, 1.0, 0.5).toColor(), // Edge: full saturation
        ],
        stops: const [0.0, 1.0],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
      
      // Draw sector
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          endAngle - startAngle,
          false,
        )
        ..close();
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}