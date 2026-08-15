import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../app/routes.dart';
import '../../core/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final authService = AuthService();
    final loggedIn = await authService.isLoggedIn();

    if (!mounted) return;
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainNav);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/other/splashscreen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Logo
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Image.asset(
                  'assets/images/logo/logo1.png',
                  height: 70,
                ),
              ),
              const SizedBox(height: 50),
              // Mascot with animation
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Mascot moves up and down continuously
                  final offset = math.sin(_controller.value * 2 * math.pi) * 10;
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/mascot/avatar1.png',
                  height: 180,
                ),
              ),
              const SizedBox(height: 24),
              // Text below mascot
              const Text(
                'The world, within reach',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4C6B38),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              // Loading Dots
              _LoadingDots(controller: _controller),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            // Calculate continuous wave for dots based on same controller
            final double value = (controller.value * 2 * math.pi) - (index * math.pi / 4);
            // We want the dot to bounce up, use a sin wave and take positive part
            final double yOffset = math.sin(value) * -5;
            
            return Transform.translate(
              offset: Offset(0, yOffset < 0 ? yOffset : 0), // Only bounce up
              child: Opacity(
                opacity: 0.5 + (yOffset < 0 ? (yOffset / -5) * 0.5 : 0),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF7BA657),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

