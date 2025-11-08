import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/ad_simple.dart';
import '../services/ad_service.dart';
import '../utils/deep_link_handler.dart';
import '../constants/app_theme.dart';
import '../constants/app_colors.dart';

/// Widget that displays ads with tracking and CTA handling
class AdBlockWidget extends StatefulWidget {
  final String placement;
  final double height;
  final double? width;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final bool autoRotate;
  final Duration autoRotateInterval;
  final Widget? fallbackWidget;

  const AdBlockWidget({
    Key? key,
    this.placement = 'home_banner',
    this.height = 180,
    this.width,
    this.margin,
    this.borderRadius,
    this.autoRotate = true,
    this.autoRotateInterval = const Duration(seconds: 5),
    this.fallbackWidget,
  }) : super(key: key);

  @override
  State<AdBlockWidget> createState() => _AdBlockWidgetState();
}

class _AdBlockWidgetState extends State<AdBlockWidget> {
  final AdService _adService = AdService();
  final PageController _pageController = PageController(viewportFraction: 0.98);
  
  List<Ad>? _ads;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAds();
    
    // Setup auto-rotation if enabled
    if (widget.autoRotate) {
      _setupAutoRotation();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load ads from service
  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _adService.getActiveAds(
        placement: widget.placement,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null && response.data!.isNotEmpty) {
            _ads = response.data;
            _errorMessage = null;
          } else {
            _ads = null;
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _ads = null;
          _errorMessage = 'Failed to load ads';
        });
      }
    }
  }

  /// Setup automatic ad rotation
  void _setupAutoRotation() {
    Future.delayed(widget.autoRotateInterval, () {
      if (mounted && _ads != null && _ads!.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _ads!.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _setupAutoRotation(); // Schedule next rotation
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return _buildLoadingState();
    }

    // No ads or error state
    if (_ads == null || _ads!.isEmpty) {
      return widget.fallbackWidget ?? _buildEmptyState();
    }

    // Render ads
    return SizedBox(
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _ads!.length,
        itemBuilder: (context, index) {
          return _AdCard(
            ad: _ads![index],
            height: widget.height,
            width: widget.width,
            margin: widget.margin,
            borderRadius: widget.borderRadius,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.fadedTextColor.withOpacity(0.1),
        borderRadius: widget.borderRadius ?? 
            BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox.shrink();
  }
}

/// Individual ad card with image and CTA
class _AdCard extends StatefulWidget {
  final Ad ad;
  final double height;
  final double? width;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const _AdCard({
    Key? key,
    required this.ad,
    required this.height,
    this.width,
    this.margin,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  final AdService _adService = AdService();
  bool _impressionTracked = false;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final imageVariant = widget.ad.getImageVariant(pixelRatio);

    return VisibilityDetector(
      key: Key('ad_${widget.ad.id}'),
      onVisibilityChanged: (info) {
        // Track impression when ad is at least 50% visible
        if (info.visibleFraction >= 0.5 && !_impressionTracked) {
          _impressionTracked = true;
          _trackImpression();
        }
      },
      child: Padding(
        padding: widget.margin ?? 
            const EdgeInsets.only(right: AppTheme.spacingMedium),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? 
              BorderRadius.circular(AppTheme.borderRadiusLarge),
          child: Stack(
            children: [
              // Ad Image
              _buildAdImage(imageVariant),
              
              // CTA Button (if available)
              if (widget.ad.cta != null)
                _buildCTA(context, widget.ad.cta!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdImage(AdImageVariant imageVariant) {
    return SizedBox(
      width: widget.width ?? MediaQuery.of(context).size.width * 0.87,
      height: widget.height,
      child: CachedNetworkImage(
        imageUrl: imageVariant.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.fadedTextColor.withOpacity(0.1),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.fadedTextColor.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: AppColors.fadedTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA(BuildContext context, AdCTA cta) {
    final containerSize = Size(
      widget.width ?? MediaQuery.of(context).size.width * 0.87,
      widget.height,
    );

    // Calculate absolute position from normalized coordinates
    final left = containerSize.width * cta.position.x;
    final top = containerSize.height * cta.position.y;

    return Positioned(
      left: left,
      top: top,
      child: _CTAButton(
        cta: cta,
        onPressed: () => _handleCTATap(context, cta),
      ),
    );
  }

  /// Track impression
  void _trackImpression() {
    _adService.reportImpression(widget.ad).then((success) {
      if (!success) {
        debugPrint('Failed to track impression for ad ${widget.ad.id}');
      }
    });
  }

  /// Handle CTA tap
  Future<void> _handleCTATap(BuildContext context, AdCTA cta) async {
    // Track click
    _adService.reportClick(widget.ad);

    // Handle navigation
    await DeepLinkHandler.handleCTA(
      context: context,
      targetUrl: cta.targetUrl,
      type: cta.type,
    );
  }
}

/// CTA Button with custom styling
class _CTAButton extends StatelessWidget {
  final AdCTA cta;
  final VoidCallback onPressed;

  const _CTAButton({
    Key? key,
    required this.cta,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = cta.style;

    return Semantics(
      button: true,
      label: cta.text,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _parseColor(style.backgroundColor) ?? 
              AppColors.primaryColor,
          foregroundColor: _parseColor(style.textColor) ?? 
              AppColors.backgroundColor,
          padding: EdgeInsets.all(style.padding ?? 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              style.borderRadius ?? AppTheme.borderRadiusLarge,
            ),
            side: style.border != null
                ? BorderSide(
                    color: _parseColor(style.border!.color) ?? Colors.transparent,
                    width: style.border!.width,
                  )
                : BorderSide.none,
          ),
          elevation: style.shadow != null ? 4 : 2,
          shadowColor: style.shadow != null
              ? _parseColor(style.shadow!.color)
              : Colors.black26,
          minimumSize: const Size(100, 44), // Minimum tappable size
        ),
        child: Text(
          cta.text,
          style: TextStyle(
            fontSize: style.fontSize ?? 14,
            fontWeight: _parseFontWeight(style.fontWeight),
          ),
        ),
      ),
    );
  }

  /// Parse hex color string to Color
  Color? _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;

    try {
      // Remove # if present
      final cleanHex = hexColor.replaceAll('#', '');
      
      // Handle both RGB and ARGB formats
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (e) {
      debugPrint('Error parsing color: $hexColor');
    }
    
    return null;
  }

  /// Parse font weight string to FontWeight
  FontWeight _parseFontWeight(String? weight) {
    if (weight == null) return FontWeight.w600;

    switch (weight.toLowerCase()) {
      case 'normal':
        return FontWeight.normal;
      case 'bold':
        return FontWeight.bold;
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '400':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '700':
        return FontWeight.w700;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return FontWeight.w600;
    }
  }
}
