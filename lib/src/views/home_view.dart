import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'main_view.dart';
import 'explore_view.dart';
import 'search_view.dart';
import 'favorites_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  int? _searchTabIndex;
  String? _searchFromText;
  String? _searchToText;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToSearch(int index, {int? tabIndex, String? fromText, String? toText}) {
    setState(() {
      _selectedIndex = index;
      _searchTabIndex = tabIndex;
      _searchFromText = fromText;
      _searchToText = toText;
    });
  }

  List<Widget> get _pages => [
    MainView(onNavigateToSearch: _navigateToSearch),
    const ExploreView(),
    SearchView(
      initialTabIndex: _searchTabIndex ?? 0,
      fromText: _searchFromText ?? '',
      toText: _searchToText ?? '',
    ),
    const FavoritesView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return ClipPath(
      clipper: TopArcClipper(),
      child: Container(
        height: 100,
        color: AppColors.backgroundColor,
        child: Stack(
          children: [
            _buildArcBorder(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildArcBorder() {
    return CustomPaint(
      painter: ArcBorderPainter(),
      child: Container(
        height: 100,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingXLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildIconButton(0, Icons.home_outlined, Icons.home),
          _buildIconButton(1, Icons.explore_outlined, Icons.explore),
          _buildFlightSearchButton(2, Icons.search_outlined, Icons.search),
          _buildIconButton(3, Icons.favorite_outline, Icons.favorite),
          _buildIconButton(4, Icons.person_outlined, Icons.person),
        ],
      ),
    );
  }

  Widget _buildIconButton(int index, IconData selectedIcon, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        isSelected ? icon : selectedIcon,
        color: isSelected ? AppColors.secondaryColor : AppColors.textColor,
        size: isSelected ? AppTheme.iconSizeMedium : AppTheme.iconSizeLarge,
      ),
    );
  }

  Widget _buildFlightSearchButton(
      int index, IconData selectedIcon, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return ClipOval(
      child: Material(
        color: AppColors.secondaryColor,
        child: InkWell(
          splashColor: AppColors.primaryColor,
          onTap: () => _onItemTapped(index),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              isSelected ? icon : selectedIcon,
              size: AppTheme.iconSizeLarge,
              color: AppColors.backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom clipper for the top arc
class TopArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 30);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 30);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom painter for drawing the border
class ArcBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.fadedTextColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Path borderPath = Path();
    borderPath.moveTo(0, 30);
    borderPath.quadraticBezierTo(size.width / 2, 0, size.width, 30);
    canvas.drawPath(borderPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
