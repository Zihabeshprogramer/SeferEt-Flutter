import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/package_provider.dart';

class PackageSearchWidget extends ConsumerStatefulWidget {
  final String? hintText;
  final VoidCallback? onSearchTap;
  final bool readOnly;
  final bool showFilters;

  const PackageSearchWidget({
    super.key,
    this.hintText,
    this.onSearchTap,
    this.readOnly = false,
    this.showFilters = true,
  });

  @override
  ConsumerState<PackageSearchWidget> createState() => _PackageSearchWidgetState();
}

class _PackageSearchWidgetState extends ConsumerState<PackageSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      ref.read(searchProvider.notifier).clearSearch();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted && query.trim().isNotEmpty) {
        ref.read(searchProvider.notifier).searchPackages(query.trim(), refresh: true);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).searchPackages(query.trim(), refresh: true);
    }
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              readOnly: widget.readOnly,
              onTap: widget.onSearchTap,
              onChanged: widget.readOnly ? null : _onSearchChanged,
              onSubmitted: widget.readOnly ? null : _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search packages...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppColors.fadedTextColor,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.fadedTextColor,
                ),
                suffixIcon: _controller.text.isNotEmpty && !widget.readOnly
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.fadedTextColor,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
              ),
              style: AppTheme.bodyMedium,
            ),
          ),
          if (widget.showFilters) ...[
            Container(
              width: 1,
              height: 30,
              color: AppColors.dividerColor,
            ),
            IconButton(
              onPressed: () {
                // TODO: Show search filters
              },
              icon: const Icon(
                Icons.tune,
                color: AppColors.fadedTextColor,
              ),
              tooltip: 'Search Filters',
            ),
          ],
        ],
      ),
    );
  }
}

class SearchResultsWidget extends ConsumerWidget {
  final ScrollController? scrollController;
  final VoidCallback? onPackageTap;

  const SearchResultsWidget({
    super.key,
    this.scrollController,
    this.onPackageTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);

    if (searchState.query.isEmpty) {
      return _buildEmptyState('Start typing to search for packages');
    }

    if (searchState.hasError && searchState.packages.isEmpty) {
      return _buildErrorState(
        searchState.errorMessage,
        () => ref.read(searchProvider.notifier).searchPackages(
          searchState.query,
          refresh: true,
        ),
      );
    }

    if (searchState.isLoading && searchState.packages.isEmpty) {
      return _buildLoadingState();
    }

    if (searchState.packages.isEmpty) {
      return _buildEmptyState('No packages found for "${searchState.query}"');
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: searchState.packages.length + (searchState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= searchState.packages.length) {
          // Load more indicator
          if (searchState.isLoading) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            // Trigger load more
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(searchProvider.notifier).loadMoreResults();
            });
            return const SizedBox.shrink();
          }
        }

        final package = searchState.packages[index];
        return _buildSearchResultCard(context, package);
      },
    );
  }

  Widget _buildSearchResultCard(BuildContext context, package) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to package details
          Navigator.pushNamed(
            context,
            '/tour-details',
            arguments: {
              'id': package.id,
              'slug': package.slug,
              'name': package.name,
              'description': package.description,
              'price': package.displayPrice,
              'rating': package.rating.average,
              'category': package.typeLabel,
            },
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  color: AppColors.primaryColor.withOpacity(0.1),
                ),
                child: package.mainImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        child: Image.network(
                          package.mainImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.mosque,
                                color: AppColors.primaryColor,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.mosque,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              // Package Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXSmall),
                    Text(
                      package.description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColors.warningColor,
                          size: 14,
                        ),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          package.rating.average.toStringAsFixed(1),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          package.durationFormatted,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.fadedTextColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${package.currency} ${package.displayPrice.toStringAsFixed(0)}',
                          style: AppTheme.titleSmall.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.fadedTextColor,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            message,
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.fadedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppTheme.spacingMedium),
          Text('Searching packages...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Search Failed',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            error,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.fadedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}