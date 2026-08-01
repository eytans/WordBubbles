import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/word_models.dart';

class AnimatedBubblesLayer extends StatefulWidget {
  final List<WordBubble> bubbles;
  final Function(WordBubble) onBubbleTap;
  final double bubbleSize;
  final double topPadding;
  final Color accentColor;
  final bool showPhotoCards;

  const AnimatedBubblesLayer({
    super.key,
    required this.bubbles,
    required this.onBubbleTap,
    required this.bubbleSize,
    this.topPadding = 0,
    this.accentColor = const Color(0xFFFF6347),
    this.showPhotoCards = false,
  });

  @override
  State<AnimatedBubblesLayer> createState() => _AnimatedBubblesLayerState();
}

class _AnimatedBubblesLayerState extends State<AnimatedBubblesLayer> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );
    _startAnimation();
  }

  void _startAnimation() {
    _animationController.repeat();
    _animationController.addListener(_updateBubblePositions);
  }

  void _updateBubblePositions() {
    if (!mounted) return;
    
    final size = context.size;
    if (size == null) return;

    final maxX = math.max(0.0, size.width - widget.bubbleSize);
    final maxY = math.max(0.0, size.height - widget.bubbleSize);
    final minY = math.min(widget.topPadding, maxY);

    bool needsUpdate = false;
    
    for (final bubble in widget.bubbles) {
      if (bubble.isClicked) continue;

      // Update position
      final newX = bubble.x + bubble.dx;
      final newY = bubble.y + bubble.dy;

      // Bounce off walls
      if (maxX == 0) {
        bubble.x = 0;
        bubble.dx = 0;
      } else if (newX <= 0 || newX >= maxX) {
        bubble.dx *= -1;
        bubble.x = newX.clamp(0.0, maxX).toDouble();
        needsUpdate = true;
      } else {
        bubble.x = newX;
        needsUpdate = true;
      }
      
      if (maxY == 0) {
        bubble.y = 0;
        bubble.dy = 0;
      } else if (newY <= minY || newY >= maxY) {
        bubble.dy *= -1;
        bubble.y = newY.clamp(minY, maxY).toDouble();
        needsUpdate = true;
      } else {
        bubble.y = newY;
        needsUpdate = true;
      }
    }

    // Only call setState if positions actually changed
    if (needsUpdate) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_updateBubblePositions);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxX = math.max(0.0, constraints.maxWidth - widget.bubbleSize);
        final maxY = math.max(0.0, constraints.maxHeight - widget.bubbleSize);
        final minY = math.min(widget.topPadding, maxY);

        return Stack(
          children: widget.bubbles.map((bubble) => Positioned(
            left: bubble.x.clamp(0.0, maxX).toDouble(),
            top: bubble.y.clamp(minY, maxY).toDouble(),
            child: Semantics(
              button: true,
              label: '${bubble.word.word}. Tap to hear the word.',
              onTap: () => widget.onBubbleTap(bubble),
              child: GestureDetector(
                onTap: () => widget.onBubbleTap(bubble),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  width: widget.bubbleSize,
                  height: widget.bubbleSize,
                  decoration: BoxDecoration(
                    color: bubble.isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.92),
                    border: Border.all(
                      color: bubble.isActive
                          ? widget.accentColor
                          : widget.accentColor.withValues(alpha: 0.85),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: bubble.isActive
                            ? widget.accentColor.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.25),
                        blurRadius: bubble.isActive ? 15 : 8,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  transform: bubble.isActive
                      ? (Matrix4.identity()..scale(1.1))
                      : Matrix4.identity(),
                  child: Center(
                    child: _buildBubbleVisual(bubble),
                  ),
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildBubbleVisual(WordBubble bubble) {
    final photoAssetPath = bubble.word.photoAssetPath;
    if (!widget.showPhotoCards || photoAssetPath == null) {
      return Text(
        bubble.word.iconUrl,
        style: const TextStyle(fontSize: 48),
        textAlign: TextAlign.center,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          photoAssetPath,
          width: widget.bubbleSize - 20,
          height: widget.bubbleSize - 20,
          fit: BoxFit.cover,
          cacheWidth: 256,
          errorBuilder: (context, error, stackTrace) => Text(
            bubble.word.iconUrl,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
