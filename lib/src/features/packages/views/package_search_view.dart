import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../core/widgets/package_search_widget.dart';
import '../../../providers/package_provider.dart';

class PackageSearchView extends ConsumerStatefulWidget {
  final String? initialQuery;

  const PackageSearchView({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<PackageSearchView> createState() => _PackageSearchViewState();
}

class _PackageSearchViewState extends ConsumerState<PackageSearchView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Set up pagination listener
    _scrollController.addListener(_onScroll);

    // If initial query provided, trigger search
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).searchPackages(widget.initialQuery!, refresh: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMoreResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Search Packages',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(searchProvider.notifier).clearSearch();
            },
            icon: const Icon(
              Icons.clear_all,
              color: AppColors.primaryColor,
            ),
            tooltip: 'Clear Search',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackTransparent,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const PackageSearchWidget(
              hintText: 'Search for Umrah packages...',
              showFilters: true,
            ),
          ),
          // Search Results
          Expanded(
            child: SearchResultsWidget(
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
    );
  }
}