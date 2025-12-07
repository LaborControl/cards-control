import 'package:flutter/material.dart';
import 'dart:math' as math;

class NfcScanAnimation extends StatefulWidget {
  final bool isScanning;
  final VoidCallback? onTap;

  const NfcScanAnimation({
    super.key,
    this.isScanning = false,
    this.onTap,
  });

  @override
  State<NfcScanAnimation> createState() => _NfcScanAnimationState();
}

class _NfcScanAnimationState extends State<NfcScanAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Animation de vagues
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isScanning) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(NfcScanAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isScanning && !oldWidget.isScanning) {
      _startAnimations();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _rippleController.stop();
    _pulseController.reset();
    _rippleController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final size = 200.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cercles de vagues (ripple)
            if (widget.isScanning)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size * 1.5, size * 1.5),
                    painter: _RipplePainter(
                      progress: _rippleAnimation.value,
                      color: primaryColor,
                    ),
                  );
                },
              ),

            // Cercle principal avec NFC
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isScanning ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: primaryColor.withOpacity(
                          widget.isScanning ? 0.8 : 0.3,
                        ),
                        width: widget.isScanning ? 3 : 2,
                      ),
                      boxShadow: widget.isScanning
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.nfc,
                        size: 80,
                        color: primaryColor.withOpacity(
                          widget.isScanning ? 1.0 : 0.7,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Indicateur de signal NFC
            if (widget.isScanning)
              Positioned(
                right: 30,
                top: 40,
                child: _NfcSignalIndicator(
                  animation: _rippleAnimation,
                  color: primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Dessiner 3 cercles à différentes phases
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1 - phase) * 0.5;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _NfcSignalIndicator extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _NfcSignalIndicator({
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final animValue = ((animation.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = math.sin(animValue * math.pi);

            return Container(
              width: 4,
              height: 12 + index * 6.0,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(opacity * 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
