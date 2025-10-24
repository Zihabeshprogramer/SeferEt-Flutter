import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/onboarding_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Auto-navigate after splash delay
    _autoNavigate();
  }

  Future<void> _autoNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Check if user has seen onboarding
    final hasSeenOnboarding = await _onboardingService.hasSeenOnboarding();
    
    if (hasSeenOnboarding) {
      // User has seen onboarding, go to sign-in
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      // First time user, show onboarding
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
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
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/Splash.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        _buildAppTitle(),
        const Spacer(),
        _buildAnimatedButton(),
        const SizedBox(height: AppTheme.spacingXLarge),
      ],
    );
  }

  Widget _buildAppTitle() {
    return Center(
      child: Text(
        'SeferEt',
        style: AppTheme.headlineLarge.copyWith(
          fontSize: 36,
          color: AppColors.textTitleColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRotatingCircle(),
          _buildInnerButton(),
        ],
      ),
    );
  }

  Widget _buildRotatingCircle() {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: FadingSemiCirclePainter(),
        ),
      ),
    );
  }

  Widget _buildInnerButton() {
    return GestureDetector(
      onTap: () async {
        // Check if user has seen onboarding
        final hasSeenOnboarding = await _onboardingService.hasSeenOnboarding();
        
        if (hasSeenOnboarding) {
          // User has seen onboarding, go to sign-in
          if (context.mounted) Navigator.pushReplacementNamed(context, '/sign-in');
        } else {
          // First time user, show onboarding
          if (context.mounted) Navigator.pushReplacementNamed(context, '/onboarding');
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: AppColors.blackTransparent,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_forward,
            color: AppColors.textTitleColor,
            size: AppTheme.iconSizeLarge,
          ),
        ),
      ),
    );
  }
}

class FadingSemiCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.secondaryColor,
          AppColors.secondaryColor.withOpacity(0),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: 45,
        ),
      )
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: 45,
      ),
      -3.14 / 2,
      3.14,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
