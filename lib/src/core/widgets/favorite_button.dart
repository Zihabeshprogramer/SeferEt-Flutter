import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';

/// A reusable favorite button widget that can be used across the app
class FavoriteButton extends ConsumerStatefulWidget {
  /// The type of item (flight, hotel, package)
  final String type;
  
  /// The item data to be saved as favorite
  final Map<String, dynamic> itemData;
  
  /// Optional reference ID for database items
  final int? referenceId;
  
  /// Optional title for the favorite item
  final String? title;
  
  /// Button size
  final double? size;
  
  /// Whether to show as icon button or regular button
  final bool iconOnly;
  
  /// Custom icon for favorited state
  final IconData? favoriteIcon;
  
  /// Custom icon for unfavorited state
  final IconData? unfavoriteIcon;
  
  /// Custom colors
  final Color? favoriteColor;
  final Color? unfavoriteColor;
  
  /// Callback for when favorite status changes
  final Function(bool isFavorite)? onFavoriteChanged;

  const FavoriteButton({
    super.key,
    required this.type,
    required this.itemData,
    this.referenceId,
    this.title,
    this.size,
    this.iconOnly = true,
    this.favoriteIcon,
    this.unfavoriteIcon,
    this.favoriteColor,
    this.unfavoriteColor,
    this.onFavoriteChanged,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    // Check if item is favorited
    final isFavorite = ref.watch(isFavoriteProvider({
      'type': widget.type,
      'referenceId': widget.referenceId,
    }));

    // Don't show favorite button for unauthenticated users
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    if (widget.iconOnly) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: IconButton(
          onPressed: _isProcessing ? null : () => _handleFavoriteToggle(),
          icon: _isProcessing
              ? SizedBox(
                  width: (widget.size ?? 24) * 0.7,
                  height: (widget.size ?? 24) * 0.7,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                )
              : Icon(
                  isFavorite
                      ? (widget.favoriteIcon ?? Icons.favorite)
                      : (widget.unfavoriteIcon ?? Icons.favorite_border),
                  color: isFavorite
                      ? (widget.favoriteColor ?? AppColors.errorColor)
                      : (widget.unfavoriteColor ?? AppColors.fadedTextColor),
                  size: widget.size ?? 24,
                ),
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _handleFavoriteToggle(),
        icon: _isProcessing
            ? SizedBox(
                width: 16,
                height: 16,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                isFavorite
                    ? (widget.favoriteIcon ?? Icons.favorite)
                    : (widget.unfavoriteIcon ?? Icons.favorite_border),
                size: 16,
              ),
        label: Text(
          isFavorite ? 'Favorited' : 'Add to Favorites',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFavorite
              ? (widget.favoriteColor ?? AppColors.errorColor)
              : (widget.unfavoriteColor ?? AppColors.primaryColor),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 36),
        ),
      ),
    );
  }

  /// Handle favorite toggle action
  Future<void> _handleFavoriteToggle() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Trigger animation
    await _animationController.forward();
    await _animationController.reverse();

    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
    final isFavorite = ref.read(isFavoriteProvider({
      'type': widget.type,
      'referenceId': widget.referenceId,
    }));

    bool success = false;

    if (isFavorite) {
      // Find the favorite ID to remove
      // This is a limitation - we need the favorite ID to remove it
      // For now, we'll show a message that user should remove from favorites page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('To remove from favorites, please use the favorites page'),
            backgroundColor: AppColors.warningColor,
          ),
        );
      }
      success = true; // Don't change state since we couldn't remove
    } else {
      // Add to favorites
      success = await favoritesNotifier.addToFavorites(
        type: widget.type,
        itemData: widget.itemData,
        referenceId: widget.referenceId,
        title: widget.title,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites!'),
              backgroundColor: AppColors.successColor,
            ),
          );
          
          // Call callback if provided
          widget.onFavoriteChanged?.call(true);
        } else {
          final error = favoritesNotifier.getAndClearError();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to add to favorites'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

/// A simple favorite icon widget without interaction
class FavoriteIcon extends ConsumerWidget {
  final String type;
  final int? referenceId;
  final double? size;
  final Color? favoriteColor;
  final Color? unfavoriteColor;

  const FavoriteIcon({
    super.key,
    required this.type,
    this.referenceId,
    this.size,
    this.favoriteColor,
    this.unfavoriteColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    // Don't show for unauthenticated users
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final isFavorite = ref.watch(isFavoriteProvider({
      'type': type,
      'referenceId': referenceId,
    }));

    return Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite
          ? (favoriteColor ?? AppColors.errorColor)
          : (unfavoriteColor ?? AppColors.fadedTextColor),
      size: size ?? 16,
    );
  }
}

/// A favorite counter widget that shows the number of favorites
class FavoriteCounter extends ConsumerWidget {
  final String? type; // null for total count
  final TextStyle? textStyle;

  const FavoriteCounter({
    super.key,
    this.type,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    // Don't show for unauthenticated users
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final countsAsync = ref.watch(favoritesCountsProvider);

    return countsAsync.when(
      data: (counts) {
        int count;
        switch (type) {
          case 'flight':
            count = counts.flight;
            break;
          case 'hotel':
            count = counts.hotel;
            break;
          case 'package':
            count = counts.package;
            break;
          default:
            count = counts.total;
        }

        return Text(
          count.toString(),
          style: textStyle ?? Theme.of(context).textTheme.bodySmall,
        );
      },
      loading: () => const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1),
      ),
      error: (_, __) => Text(
        '0',
        style: textStyle ?? Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}