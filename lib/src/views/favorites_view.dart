import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/favorites_service.dart';

class FavoritesView extends ConsumerStatefulWidget {
  const FavoritesView({super.key});

  @override
  ConsumerState<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends ConsumerState<FavoritesView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    // Show login prompt if user is not authenticated
    if (!authState.isAuthenticated) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'My Favorites',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showSortDialog,
            icon: const Icon(
              Icons.sort,
              color: AppColors.primaryColor,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.fadedTextColor,
          labelStyle: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.bodyMedium,
          indicatorColor: AppColors.primaryColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.flight),
              text: 'Flights',
            ),
            Tab(
              icon: Icon(Icons.hotel),
              text: 'Hotels',
            ),
            Tab(
              icon: Icon(Icons.card_travel),
              text: 'Packages',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab('flight'),
          _buildFavoritesTab('hotel'),
          _buildFavoritesTab('package'),
        ],
      ),
    );
  }

  /// Build login prompt for unauthenticated users
  Widget _buildLoginPrompt() {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'My Favorites',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.fadedTextColor,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'Sign in to view your favorites',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.fadedTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXLarge),
              child: Text(
                'Save your favorite flights, hotels, and packages to access them anytime across all your devices.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.fadedTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                Navigator.pushNamed(context, '/sign-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingMedium,
                ),
              ),
              child: Text(
                'Sign In',
                style: AppTheme.buttonText,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            TextButton(
              onPressed: () {
                // Navigate to registration screen
                Navigator.pushNamed(context, '/register');
              },
              child: Text(
                'Create Account',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build favorites tab for a specific type
  Widget _buildFavoritesTab(String type) {
    final favoritesAsync = ref.watch(favoritesProvider(type));
    
    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return _buildEmptyState(type);
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(favoritesProvider(type));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return _buildFavoriteCard(favorite);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Failed to load favorites',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              error.toString(),
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.fadedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(favoritesProvider(type));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state for a specific favorite type
  Widget _buildEmptyState(String type) {
    final config = _getEmptyStateConfig(type);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 80,
            color: AppColors.fadedTextColor,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Text(
            config['title'] as String,
            style: AppTheme.titleLarge.copyWith(
              color: AppColors.fadedTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXLarge),
            child: Text(
              config['subtitle'] as String,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.fadedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          ElevatedButton(
            onPressed: config['onPressed'] as VoidCallback,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLarge,
                vertical: AppTheme.spacingMedium,
              ),
            ),
            child: Text(
              config['buttonText'] as String,
              style: AppTheme.buttonText,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get empty state configuration for different types
  Map<String, dynamic> _getEmptyStateConfig(String type) {
    switch (type) {
      case 'flight':
        return {
          'icon': Icons.flight,
          'title': 'No Favorite Flights',
          'subtitle': 'Search for flights and save the ones you like!',
          'buttonText': 'Search Flights',
          'onPressed': () => Navigator.pushNamed(context, '/flights'),
        };
      case 'hotel':
        return {
          'icon': Icons.hotel,
          'title': 'No Favorite Hotels',
          'subtitle': 'Browse hotels and add your favorites for easy access!',
          'buttonText': 'Browse Hotels',
          'onPressed': () => Navigator.pushNamed(context, '/hotels'),
        };
      case 'package':
        return {
          'icon': Icons.card_travel,
          'title': 'No Favorite Packages',
          'subtitle': 'Explore travel packages and save the ones that interest you!',
          'buttonText': 'Explore Packages',
          'onPressed': () => Navigator.pushNamed(context, '/explore-screen'),
        };
      default:
        return {
          'icon': Icons.favorite_border,
          'title': 'No Favorites',
          'subtitle': 'Start exploring and add items to your favorites!',
          'buttonText': 'Explore',
          'onPressed': () => Navigator.pushNamed(context, '/home'),
        };
    }
  }

  /// Build favorite item card based on type
  Widget _buildFavoriteCard(FavoriteItem favorite) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onFavoriteItemTap(favorite),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildFavoriteIcon(favorite.type),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.title,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),
                        _buildFavoriteSubtitle(favorite),
                      ],
                    ),
                  ),
                  _buildFavoritePrice(favorite),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleFavoriteAction(value, favorite),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'notes',
                        child: ListTile(
                          leading: Icon(Icons.edit_note),
                          title: Text('Edit Notes'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: AppColors.errorColor),
                          title: Text('Remove from Favorites'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: AppColors.fadedTextColor,
                    ),
                  ),
                ],
              ),
              if (favorite.notes != null && favorite.notes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    favorite.notes!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  if (!favorite.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        'No longer available',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.errorColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Added ${_getTimeAgo(favorite.createdAt)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.fadedTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build icon for favorite type
  Widget _buildFavoriteIcon(String type) {
    IconData icon;
    switch (type) {
      case 'flight':
        icon = Icons.flight;
        break;
      case 'hotel':
        icon = Icons.hotel;
        break;
      case 'package':
        icon = Icons.card_travel;
        break;
      default:
        icon = Icons.favorite;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Icon(
        icon,
        color: AppColors.primaryColor,
        size: 20,
      ),
    );
  }
  
  /// Build subtitle for favorite item
  Widget _buildFavoriteSubtitle(FavoriteItem favorite) {
    final data = favorite.itemData;
    String subtitle = '';
    
    switch (favorite.type) {
      case 'flight':
        final from = data['from'] ?? data['departure_city'] ?? '';
        final to = data['to'] ?? data['arrival_city'] ?? '';
        subtitle = '$from → $to';
        if (data['airline'] != null) {
          subtitle = '${data['airline']} • $subtitle';
        }
        break;
      case 'hotel':
        final location = data['city'] ?? data['location'] ?? '';
        final rating = data['rating'];
        if (location.isNotEmpty) subtitle = location;
        if (rating != null) {
          subtitle = subtitle.isEmpty ? '★ $rating' : '$subtitle • ★ $rating';
        }
        break;
      case 'package':
        final destination = data['destination'] ?? data['location'] ?? '';
        final duration = data['duration'] ?? data['days'];
        if (destination.isNotEmpty) subtitle = destination;
        if (duration != null) {
          final durationText = duration is int ? '$duration days' : duration.toString();
          subtitle = subtitle.isEmpty ? durationText : '$subtitle • $durationText';
        }
        break;
    }
    
    return Text(
      subtitle.isNotEmpty ? subtitle : 'Favorite ${favorite.type}',
      style: AppTheme.bodySmall.copyWith(
        color: AppColors.fadedTextColor,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// Build price widget for favorite item
  Widget _buildFavoritePrice(FavoriteItem favorite) {
    final data = favorite.itemData;
    final price = data['price'];
    
    if (price == null) return const SizedBox.shrink();
    
    return Text(
      '\$${price.toString()}',
      style: AppTheme.bodyLarge.copyWith(
        color: AppColors.primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  /// Handle favorite item tap
  void _onFavoriteItemTap(FavoriteItem favorite) {
    // Navigate to appropriate detail screen based on type
    switch (favorite.type) {
      case 'flight':
        // Navigator.pushNamed(context, '/flight-details', arguments: favorite.itemData);
        break;
      case 'hotel':
        // Navigator.pushNamed(context, '/hotel-details', arguments: favorite.itemData);
        break;
      case 'package':
        // Navigator.pushNamed(context, '/package-details', arguments: favorite.itemData);
        break;
    }
  }
  
  /// Handle favorite action (share, edit notes, remove)
  void _handleFavoriteAction(String action, FavoriteItem favorite) async {
    switch (action) {
      case 'share':
        _shareItem(favorite.title);
        break;
      case 'notes':
        _showEditNotesDialog(favorite);
        break;
      case 'remove':
        _showRemoveDialog(favorite);
        break;
    }
  }
  
  /// Show edit notes dialog
  void _showEditNotesDialog(FavoriteItem favorite) {
    final controller = TextEditingController(text: favorite.notes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add your notes here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(favoritesNotifierProvider.notifier)
                  .updateFavoriteNotes(favorite.id, controller.text.trim().isEmpty ? null : controller.text.trim());
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notes updated successfully'),
                    backgroundColor: AppColors.successColor,
                  ),
                );
              } else {
                final error = ref.read(favoritesNotifierProvider.notifier).getAndClearError();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Failed to update notes'),
                    backgroundColor: AppColors.errorColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  /// Show remove confirmation dialog
  void _showRemoveDialog(FavoriteItem favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: Text('Are you sure you want to remove "${favorite.title}" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(favoritesNotifierProvider.notifier)
                  .removeFromFavorites(favorite.id);
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removed from favorites'),
                    backgroundColor: AppColors.successColor,
                  ),
                );
              } else {
                final error = ref.read(favoritesNotifierProvider.notifier).getAndClearError();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Failed to remove from favorites'),
                    backgroundColor: AppColors.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Get time ago string from date
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Share item functionality
  void _shareItem(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing $name...'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  /// Show sort options dialog
  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Favorites',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Most Recent'),
              onTap: () {
                // TODO: Implement sorting by date
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Price: Low to High'),
              onTap: () {
                // TODO: Implement sorting by price
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Alphabetical'),
              onTap: () {
                // TODO: Implement sorting alphabetically
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
