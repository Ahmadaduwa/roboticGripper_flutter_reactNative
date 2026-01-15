import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForceIndicator extends StatefulWidget {
  final double forceValue;
  final double maxForce;
  final double size;

  const ForceIndicator({
    super.key,
    required this.forceValue,
    this.maxForce = 10.0,
    this.size = 180,
  });

  @override
  State<ForceIndicator> createState() => _ForceIndicatorState();
}

class _ForceIndicatorState extends State<ForceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ForceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.forceValue != widget.forceValue && widget.forceValue > 0.5) {
      _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.forceValue.isNaN
        ? 0.0
        : widget.forceValue.clamp(0.0, widget.maxForce);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0D47A1), // Darker blue center
                  const Color(0xFF1565C0), // Medium blue
                  const Color(0xFF1976D2), // Lighter blue edge
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: const Color(0xFF64DD17), // Bright green border
                width: widget.size * 0.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64DD17).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toStringAsFixed(2), // 2 decimal places
                    style: GoogleFonts.zillaSlab(
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "N",
                    style: GoogleFonts.outfit(
                      fontSize: widget.size * 0.15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
