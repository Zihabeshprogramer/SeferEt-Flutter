import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/onboarding_service.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final OnboardingService _onboardingService = OnboardingService();

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/venice.png",
      "title": "Explore The World",
      "description":
          "Discover new places, cultures, and experiences. Unlock the doors to adventure and wanderlust.",
    },
    {
      "image": "assets/images/moscow.png",
      "title": "Choose Destination",
      "description":
          "Find your perfect vacation spot. Plan your perfect getaway and trip.",
    },
    {
      "image": "assets/images/desert.png",
      "title": "Enjoy Your Trip",
      "description":
          "Find your perfect vacation spot. Plan your perfect getaway and trip.",
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildPageView(),
          _buildDotsIndicator(),
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return OnboardingPage(
          image: _pages[index]["image"]!,
          title: _pages[index]["title"]!,
          description: _pages[index]["description"]!,
          isLastPage: index == _pages.length - 1,
          pageController: _pageController,
        );
      },
    );
  }

  Widget _buildDotsIndicator() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pages.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: _currentIndex == index ? 20 : 8,
            height: _currentIndex == index ? 6 : 8,
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? AppColors.secondaryColor
                  : AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      top: 50,
      right: 20,
      child: GestureDetector(
        onTap: () async {
          await _onboardingService.completeOnboarding();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/sign-in');
          }
        },
        child: Text(
          "Skip",
          style: AppTheme.bodyLarge.copyWith(
            color: AppColors.backgroundColor,
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final bool isLastPage;
  final PageController pageController;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    this.isLastPage = false,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundImage(),
        _buildDarkOverlay(),
        _buildContent(context),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return Image.asset(
      image,
      fit: BoxFit.cover,
    );
  }

  Widget _buildDarkOverlay() {
    return Container(
      color: AppColors.blackTransparent,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTitle(),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildDescription(),
          const SizedBox(height: AppTheme.spacingXLarge + AppTheme.spacingSmall),
          _buildActionButton(),
          const SizedBox(height: AppTheme.spacingXLarge + AppTheme.spacingSmall),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppTheme.headlineSmall.copyWith(
        color: AppColors.backgroundColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      description,
      textAlign: TextAlign.center,
      style: AppTheme.bodyLarge.copyWith(
        color: AppColors.backgroundColor,
      ),
    );
  }

  Widget _buildActionButton() {
    if (isLastPage) {
      return const GetStartedButton();
    } else {
      return FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: AppColors.secondaryColor,
        onPressed: () {
          pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.arrow_forward),
      );
    }
  }
}

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: InkWell(
          onTap: () async {
            final onboardingService = OnboardingService();
            await onboardingService.completeOnboarding();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/sign-in');
            }
          },
          child: Container(
            height: 70,
            width: MediaQuery.of(context).size.width / 1.2,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge,
            ),
            decoration: BoxDecoration(
              color: AppColors.whiteTransparent,
              borderRadius: BorderRadius.circular(50.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Get Started",
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.textTitleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall + AppTheme.spacingXSmall),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.textTitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
