import 'package:flutter/material.dart';
// ignore: unused_import
import '../config/app_colors.dart';
import 'dart:math' as math;

class WelcomePopup extends StatefulWidget {
  final VoidCallback onClose;

  const WelcomePopup({required this.onClose, super.key});

  @override
  State<WelcomePopup> createState() => _WelcomePopupState();
}

class _WelcomePopupState extends State<WelcomePopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _snowController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late List<Snowflake> _snowflakes;

  @override
  void initState() {
    super.initState();
    
    // Main popup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Snow animation
    _snowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Bounce animation for icon
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));

    // Initialize snowflakes
    _snowflakes = List.generate(15, (index) => Snowflake());

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _snowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Stack(
                  children: [
                    // Snow animation
                    AnimatedBuilder(
                      animation: _snowController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SnowPainter(_snowflakes, _snowController.value),
                          size: Size(280, 350),
                        );
                      },
                    ),
                    // Main popup container
                    Container(
                      width: 280, // Made smaller
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1E88E5), // Blue similar to the image
                            Color(0xFF1565C0), // Darker blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 8,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 15,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close button
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 5),
                          
                          // Animated welcome icon
                          AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _bounceAnimation.value,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.orange, Colors.deepOrange],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.celebration,
                                    color: Colors.white,
                                    size: 35,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Main welcome text with shimmer effect
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Colors.yellow, Colors.white],
                            ).createShader(bounds),
                            child: const Text(
                              'KARIBU SANA\nFARAMAS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Description text
                          const Text(
                            'Unaazaje kuteseka kuhusu nyumba, apartments, au kiwanja, Tafuta nyumba mkononi, ukiwa nasi',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 18),
                          
                          // Animated close button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onClose,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Anza',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Snowflake class for snow animation
class Snowflake {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double opacity;

  Snowflake() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble() * 280;
    y = -10;
    speed = 1 + math.Random().nextDouble() * 3;
    size = 2 + math.Random().nextDouble() * 4;
    opacity = 0.3 + math.Random().nextDouble() * 0.7;
  }

  void update() {
    y += speed;
    x += math.sin(y * 0.01) * 0.5;
    
    if (y > 350) {
      reset();
    }
  }
}

// Custom painter for snow effect
class SnowPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  final double animationValue;

  SnowPainter(this.snowflakes, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var snowflake in snowflakes) {
      snowflake.update();
      paint.color = Colors.white.withOpacity(snowflake.opacity);
      canvas.drawCircle(
        Offset(snowflake.x, snowflake.y),
        snowflake.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
