import 'package:flutter/material.dart';
import '../models/word_models.dart';

class AnimatedBubblesLayer extends StatefulWidget {
  final List<WordBubble> bubbles;
  final Function(WordBubble) onBubbleTap;
  final double bubbleSize;
  final Color? accentColor;

  const AnimatedBubblesLayer({
    super.key,
    required this.bubbles,
    required this.onBubbleTap,
    required this.bubbleSize,
    this.accentColor,
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
    
    final screenSize = MediaQuery.of(context).size;
    final maxX = (screenSize.width - widget.bubbleSize).clamp(widget.bubbleSize, double.infinity);
    final maxY = (screenSize.height - widget.bubbleSize - 100).clamp(widget.bubbleSize, double.infinity);

    bool needsUpdate = false;
    
    for (final bubble in widget.bubbles) {
      if (bubble.isClicked) continue;

      // Update position
      final newX = bubble.x + bubble.dx;
      final newY = bubble.y + bubble.dy;

      // Bounce off walls
      if (newX <= 0 || newX >= maxX) {
        bubble.dx *= -1;
        bubble.x = newX.clamp(0, maxX);
        needsUpdate = true;
      } else {
        bubble.x = newX;
        needsUpdate = true;
      }
      
      if (newY <= 0 || newY >= maxY) {
        bubble.dy *= -1;
        bubble.y = newY.clamp(0, maxY);
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
    return Stack(
      children: widget.bubbles.map((bubble) => Positioned(
        left: bubble.x,
        top: bubble.y,
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
                  : Colors.white.withValues(alpha: 0.94),
              border: Border.all(
                color: bubble.isActive 
                    ? (widget.accentColor ?? const Color(0xFFFFA500)) 
                    : (widget.accentColor?.withValues(alpha: 0.8) ?? const Color(0xFFFF6347)),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: bubble.isActive 
                      ? (widget.accentColor ?? const Color(0xFFFFD700)).withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.20),
                  blurRadius: bubble.isActive ? 18 : 10,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            transform: bubble.isActive 
                ? (Matrix4.identity()..scale(1.1))
                : Matrix4.identity(),
            child: Center(
              child: Text(
                bubble.word.iconUrl,
                style: TextStyle(fontSize: (widget.bubbleSize * 0.40).clamp(28, 56).toDouble()),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}
