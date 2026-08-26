import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _letterAController;
  late AnimationController _letterSController;
  late AnimationController _letterIController;
  late AnimationController _letterQController;
  late AnimationController _lineController;
  late AnimationController _taglineController;
  late AnimationController _footerController;

  late Animation<double> _letterAAnimation;
  late Animation<double> _letterSAnimation;
  late Animation<double> _letterIAnimation;
  late Animation<double> _letterQAnimation;
  late Animation<double> _lineAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _footerAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    
    // Navigate after all animations complete
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _initAnimations() {
    // Letter A - delay 100ms
    _letterAController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _letterAAnimation = CurvedAnimation(
      parent: _letterAController,
      curve: Curves.easeOutBack,
    );

    // Letter S - delay 550ms
    _letterSController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _letterSAnimation = CurvedAnimation(
      parent: _letterSController,
      curve: Curves.easeOutBack,
    );

    // Letter I - delay 750ms
    _letterIController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _letterIAnimation = CurvedAnimation(
      parent: _letterIController,
      curve: Curves.easeOutBack,
    );

    // Letter Q - delay 950ms
    _letterQController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _letterQAnimation = CurvedAnimation(
      parent: _letterQController,
      curve: Curves.easeOutBack,
    );

    // Underline - delay 1300ms
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeInOut,
    );

    // Tagline - delay 1500ms
    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _taglineAnimation = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    );

    // Footer - delay 1750ms
    _footerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _footerAnimation = CurvedAnimation(
      parent: _footerController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    // Start each animation with proper delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _letterAController.forward();
    });

    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _letterSController.forward();
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) _letterIController.forward();
    });

    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) _letterQController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _lineController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _taglineController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1750), () {
      if (mounted) _footerController.forward();
    });
  }

  @override
  void dispose() {
    _letterAController.dispose();
    _letterSController.dispose();
    _letterIController.dispose();
    _letterQController.dispose();
    _lineController.dispose();
    _taglineController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;
    final fontSize = isSmall ? 64.0 : (size.width * 0.16).clamp(64.0, 170.0);
    final underlineWidth = isSmall ? 80.0 : (size.width * 0.14).clamp(80.0, 180.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ASIQ Wordmark
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAnimatedLetter(
                        'A',
                        const Color(0xFF5393E0),
                        _letterAAnimation,
                        fontSize,
                      ),
                      _buildAnimatedLetter(
                        'S',
                        const Color(0xFF3579C5),
                        _letterSAnimation,
                        fontSize,
                      ),
                      _buildAnimatedLetter(
                        'I',
                        const Color(0xFF1F6DB8),
                        _letterIAnimation,
                        fontSize,
                      ),
                      _buildAnimatedLetter(
                        'Q',
                        const Color(0xFF0860AA),
                        _letterQAnimation,
                        fontSize,
                      ),
                    ],
                  ),

                  // Animated underline
                  SizedBox(height: isSmall ? 14.0 : 20.0),
                  AnimatedBuilder(
                    animation: _lineAnimation,
                    builder: (context, child) {
                      return Container(
                        width: underlineWidth * _lineAnimation.value,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5393E0),
                              Color(0xFF0860AA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),

                  // Tagline
                  SizedBox(height: isSmall ? 16.0 : 24.0),
                  AnimatedBuilder(
                    animation: _taglineAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _taglineAnimation.value,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            8 * (1 - _taglineAnimation.value),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Absensi Siswa Berbasis QR Code',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmall ? 14.0 : 18.0,
                                color: const Color(0xFF8A8F9C),
                                letterSpacing: 0.01,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Positioned(
              bottom: isSmall ? 28.0 : 48.0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _footerAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _footerAnimation.value,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        8 * (1 - _footerAnimation.value),
                      ),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'CREATED BY ',
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmall ? 11.0 : 13.0,
                                  color: const Color(0xFF8A8F9C),
                                  letterSpacing: 0.12,
                                ),
                              ),
                              TextSpan(
                                text: 'TIM KKNT UNESA',
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmall ? 11.0 : 13.0,
                                  color: const Color(0xFF3579C5),
                                  letterSpacing: 0.12,
                                ),
                              ),
                              TextSpan(
                                text: ' · 2026',
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmall ? 11.0 : 13.0,
                                  color: const Color(0xFF8A8F9C),
                                  letterSpacing: 0.12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLetter(
    String letter,
    Color color,
    Animation<double> animation,
    double fontSize,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Custom bounce animation
        double progress = animation.value;
        double opacity = progress.clamp(0.0, 1.0);
        
        double translateY;
        double scale;
        
        if (progress < 0.55) {
          // 0% to 55%: bounce from top to below center
          double t = progress / 0.55;
          translateY = -140 * (1 - t) + 14 * t;
          scale = 0.45 + (1.12 - 0.45) * t;
        } else if (progress < 0.75) {
          // 55% to 75%: slight bounce up
          double t = (progress - 0.55) / 0.2;
          translateY = 14 * (1 - t) + (-8) * t;
          scale = 1.12 * (1 - t) + 0.96 * t;
        } else {
          // 75% to 100%: settle to final position
          double t = (progress - 0.75) / 0.25;
          translateY = -8 * (1 - t);
          scale = 0.96 + (1.0 - 0.96) * t;
        }

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0860AA).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  letter,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
