import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/flight_models.dart';
import '../../services/api_service.dart';
import '../../../services/amadeus_flight_service.dart';

/// Airport autocomplete field with live search
class AirportAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Function(Airport) onAirportSelected;

  const AirportAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onAirportSelected,
  });

  @override
  State<AirportAutocompleteField> createState() => _AirportAutocompleteFieldState();
}

class _AirportAutocompleteFieldState extends State<AirportAutocompleteField> {
  final ApiService _apiService = ApiService();
  late final AmadeusFlightService _flightService;
  Timer? _debounce;
  List<Airport> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _flightService = AmadeusFlightService(
      baseUrl: 'http://172.20.10.9:8000',
      dio: null,
    );
    widget.controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = widget.controller.text.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAirports(query);
    });
  }

  Future<void> _searchAirports(String keyword) async {
    if (keyword.length < 2) return;

    setState(() => _isLoading = true);

    try {
      final token = _apiService.authToken ?? '';
      
      // Debug logging
      print('🔍 Searching airports: keyword="$keyword"');
      print('📡 API endpoint: http://172.20.10.9:8000/api/flights/airports');
      print('🔑 Token available: ${token.isNotEmpty}');
      
      final results = await _flightService.searchAirports(
        keyword: keyword,
        token: token,
      );

      print('✅ Airport search success: ${results.length} results');

      setState(() {
        _suggestions = results.map((e) => Airport.fromJson(e)).toList();
        _showSuggestions = _suggestions.isNotEmpty;
        _isLoading = false;
      });

      if (_showSuggestions && _focusNode.hasFocus) {
        _showOverlay();
      }
    } catch (e) {
      print('❌ Airport search error: $e');
      setState(() {
        _isLoading = false;
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    // Get the RenderBox to determine width
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final airport = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.flight_takeoff,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    title: Text(
                      airport.name,
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${airport.cityName ?? ''} (${airport.iataCode})',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                    ),
                    onTap: () {
                      widget.controller.text = airport.iataCode;
                      widget.onAirportSelected(airport);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          color: AppColors.backgroundColor,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: AppTheme.bodyMedium,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            labelStyle: AppTheme.bodySmall.copyWith(
              color: AppColors.primaryColor,
              fontSize: 12,
            ),
            hintStyle: AppTheme.bodySmall.copyWith(
              color: AppColors.fadedTextColor,
              fontSize: 12,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: AppTheme.spacingSmall,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
