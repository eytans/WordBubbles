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

  const DecorativeFrame({
    super.key,
    required this.child,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(style);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.borderGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.panelGradient,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  _FramePalette _paletteFor(FrameStyle value) {
    switch (value) {
      case FrameStyle.candy:
        return const _FramePalette(
          borderGradient: [Color(0xFFFFE082), Color(0xFFFF8A65)],
          panelGradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          shadowColor: Color(0x40000000),
        );
      case FrameStyle.ocean:
        return const _FramePalette(
          borderGradient: [Color(0xFF81D4FA), Color(0xFF0288D1)],
          panelGradient: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
          shadowColor: Color(0x40000000),
        );
      case FrameStyle.forest:
        return const _FramePalette(
          borderGradient: [Color(0xFFA5D6A7), Color(0xFF388E3C)],
          panelGradient: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          shadowColor: Color(0x40000000),
        );
      case FrameStyle.galaxy:
        return const _FramePalette(
          borderGradient: [Color(0xFFB39DDB), Color(0xFF512DA8)],
          panelGradient: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
          shadowColor: Color(0x40000000),
        );
    }
  }
}

class _FramePalette {
  final List<Color> borderGradient;
  final List<Color> panelGradient;
  final Color shadowColor;

  const _FramePalette({
    required this.borderGradient,
    required this.panelGradient,
    required this.shadowColor,
  });
}
