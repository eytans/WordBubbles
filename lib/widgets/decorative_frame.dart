import 'package:flutter/material.dart';

enum FrameStyle {
  candy,
  ocean,
  forest,
  galaxy,
}

class DecorativeFrame extends StatelessWidget {
  final Widget child;
  final FrameStyle style;
  final EdgeInsetsGeometry? margin;

  const DecorativeFrame({
    super.key,
    required this.child,
    required this.style,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final bool isLandscape = screenSize.width > screenSize.height;

    final double basePadding = isTablet ? 24 : 16;
    final double frameThickness = isTablet
        ? (isLandscape ? 18 : 20)
        : (isLandscape ? 12 : 14);
    final double cornerRadius = isTablet ? 28 : 22;

    final _FramePalette palette = _paletteFor(style);

    return Container(
      margin: margin ?? EdgeInsets.all(basePadding.toDouble()),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: isTablet ? 30 : 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius - 2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.panelGradient,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Outer decorative stroke
              _GradientBorder(
                thickness: frameThickness,
                radius: cornerRadius,
                colors: palette.borderGradient,
              ),

              // Inner subtle glow
              _InnerGlow(
                radius: cornerRadius,
                color: palette.glowColor,
              ),

              // The framed content
              Padding(
                padding: EdgeInsets.all((basePadding - 4).toDouble()),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _FramePalette _paletteFor(FrameStyle style) {
    switch (style) {
      case FrameStyle.candy:
        return _FramePalette(
          borderGradient: const [Color(0xFFFFE082), Color(0xFFFF8A65)],
          panelGradient: const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          glowColor: const Color(0xFFFFCC80).withValues(alpha: 0.3),
        );
      case FrameStyle.ocean:
        return _FramePalette(
          borderGradient: const [Color(0xFF81D4FA), Color(0xFF29B6F6)],
          panelGradient: const [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
          glowColor: const Color(0xFF4FC3F7).withValues(alpha: 0.25),
        );
      case FrameStyle.forest:
        return _FramePalette(
          borderGradient: const [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
          panelGradient: const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          glowColor: const Color(0xFF81C784).withValues(alpha: 0.25),
        );
      case FrameStyle.galaxy:
        return _FramePalette(
          borderGradient: const [Color(0xFFB39DDB), Color(0xFF7E57C2)],
          panelGradient: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
          glowColor: const Color(0xFF9575CD).withValues(alpha: 0.28),
        );
    }
  }
}

class _FramePalette {
  final List<Color> borderGradient;
  final List<Color> panelGradient;
  final Color glowColor;
  const _FramePalette({
    required this.borderGradient,
    required this.panelGradient,
    required this.glowColor,
  });
}

class _GradientBorder extends StatelessWidget {
  final double thickness;
  final double radius;
  final List<Color> colors;

  const _GradientBorder({
    required this.thickness,
    required this.radius,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientBorderPainter(
        thickness: thickness,
        radius: radius,
        colors: colors,
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double thickness;
  final double radius;
  final List<Color> colors;

  _GradientBorderPainter({
    required this.thickness,
    required this.radius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final Paint paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawRRect(rrect.deflate(thickness / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.thickness != thickness ||
        oldDelegate.radius != radius ||
        oldDelegate.colors != colors;
  }
}

class _InnerGlow extends StatelessWidget {
  final double radius;
  final Color color;

  const _InnerGlow({
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius - 4),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const SizedBox.expand(),
    );
  }
}

