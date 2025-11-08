import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

/// City data model for autocomplete
class City {
  final String name;
  final String code;
  final String? country;

  City({
    required this.name,
    required this.code,
    this.country,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String? ?? json['city_name'] as String? ?? '',
      code: json['code'] as String? ?? json['city_code'] as String? ?? json['iata_code'] as String? ?? '',
      country: json['country'] as String?,
    );
  }

  String get displayName {
    if (country != null && country!.isNotEmpty) {
      return '$name, $country';
    }
    return name;
  }
}

/// City autocomplete field with suggestions
class CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Function(City) onCitySelected;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onCitySelected,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  Timer? _debounce;
  List<City> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // Popular cities list (can be fetched from API in production)
  final List<City> _popularCities = [
    City(name: 'London', code: 'LON', country: 'United Kingdom'),
    City(name: 'New York', code: 'NYC', country: 'United States'),
    City(name: 'Paris', code: 'PAR', country: 'France'),
    City(name: 'Dubai', code: 'DXB', country: 'United Arab Emirates'),
    City(name: 'Tokyo', code: 'TYO', country: 'Japan'),
    City(name: 'Istanbul', code: 'IST', country: 'Turkey'),
    City(name: 'Rome', code: 'ROM', country: 'Italy'),
    City(name: 'Barcelona', code: 'BCN', country: 'Spain'),
    City(name: 'Amsterdam', code: 'AMS', country: 'Netherlands'),
    City(name: 'Singapore', code: 'SIN', country: 'Singapore'),
    City(name: 'Bangkok', code: 'BKK', country: 'Thailand'),
    City(name: 'Los Angeles', code: 'LAX', country: 'United States'),
    City(name: 'Hong Kong', code: 'HKG', country: 'Hong Kong'),
    City(name: 'Sydney', code: 'SYD', country: 'Australia'),
    City(name: 'Berlin', code: 'BER', country: 'Germany'),
    City(name: 'Madrid', code: 'MAD', country: 'Spain'),
    City(name: 'Vienna', code: 'VIE', country: 'Austria'),
    City(name: 'Athens', code: 'ATH', country: 'Greece'),
    City(name: 'Prague', code: 'PRG', country: 'Czech Republic'),
    City(name: 'Lisbon', code: 'LIS', country: 'Portugal'),
    City(name: 'Mecca', code: 'JED', country: 'Saudi Arabia'),
    City(name: 'Medina', code: 'MED', country: 'Saudi Arabia'),
    City(name: 'Addis Ababa', code: 'ADD', country: 'Ethiopia'),
    City(name: 'Cairo', code: 'CAI', country: 'Egypt'),
  ];

  @override
  void initState() {
    super.initState();
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
    print('🔍 City field focus changed: ${_focusNode.hasFocus}');
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else if (widget.controller.text.isEmpty) {
      // Show popular cities when focused with empty field
      print('📍 Showing popular cities (${_popularCities.length} cities)');
      setState(() {
        _suggestions = _popularCities;
        _showSuggestions = true;
      });
      // Delay overlay show to ensure widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus) {
          _showOverlay();
        }
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = widget.controller.text.trim();
    
    if (query.isEmpty) {
      // Show popular cities when empty
      setState(() {
        _suggestions = _popularCities;
        _showSuggestions = true;
      });
      if (_focusNode.hasFocus) {
        _showOverlay();
      }
      return;
    }
    
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchCities(query);
    });
  }

  void _searchCities(String keyword) {
    if (keyword.length < 2) return;

    setState(() => _isLoading = true);

    print('🔎 Searching cities for: "$keyword"');

    // Filter popular cities based on search query
    // In production, this would be an API call
    final lowerKeyword = keyword.toLowerCase();
    final results = _popularCities.where((city) {
      return city.name.toLowerCase().contains(lowerKeyword) ||
          city.code.toLowerCase().contains(lowerKeyword) ||
          (city.country?.toLowerCase().contains(lowerKeyword) ?? false);
    }).toList();

    print('✅ Found ${results.length} cities');

    setState(() {
      _suggestions = results;
      _showSuggestions = _suggestions.isNotEmpty;
      _isLoading = false;
    });

    if (_showSuggestions && _focusNode.hasFocus) {
      print('📋 Showing overlay with ${_suggestions.length} suggestions');
      _showOverlay();
    } else {
      print('❌ Not showing overlay: showSuggestions=$_showSuggestions, hasFocus=${_focusNode.hasFocus}');
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    print('🎯 Attempting to show overlay...');

    // Get the RenderBox to determine width
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print('⚠️ RenderBox is null, retrying...');
      // Retry after next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus) {
          _showOverlay();
        }
      });
      return;
    }

    print('✓ RenderBox found, size: ${renderBox.size}');
    print('✓ Suggestions count: ${_suggestions.length}');
    
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingSmall),
                      child: Text(
                        'Popular Destinations',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.fadedTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  Flexible(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final city = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_city,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          title: Text(
                            city.name,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: city.country != null
                              ? Text(
                                  city.country!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.fadedTextColor,
                                  ),
                                )
                              : null,
                          trailing: Text(
                            city.code,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            widget.controller.text = city.name;
                            widget.onCitySelected(city);
                            _removeOverlay();
                            _focusNode.unfocus();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      Overlay.of(context).insert(_overlayEntry!);
      print('✅ Overlay inserted successfully!');
    } catch (e) {
      print('❌ Failed to insert overlay: $e');
      // Overlay not available yet, retry
      _overlayEntry = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus && _showSuggestions) {
          print('🔄 Retrying overlay insertion...');
          _showOverlay();
        }
      });
    }
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
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          color: AppColors.backgroundColor,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: AppTheme.bodyMedium,
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
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.fadedTextColor,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() {
                            _suggestions = _popularCities;
                            _showSuggestions = true;
                          });
                          if (_focusNode.hasFocus) {
                            _showOverlay();
                          }
                        },
                      )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: AppTheme.spacingMedium,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
