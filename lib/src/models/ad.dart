import 'package:json_annotation/json_annotation.dart';

part 'ad.g.dart';

/// Represents an advertisement with images, CTA, and tracking configuration
@JsonSerializable(explicitToJson: true)
class Ad {
  final String id;
  final String name;
  final String? description;
  
  /// Image variants for different densities
  @JsonKey(name: 'image_variants')
  final List<AdImageVariant> imageVariants;
  
  /// Call-to-action configuration
  final AdCTA? cta;
  
  /// Tracking configuration
  @JsonKey(name: 'tracking_urls')
  final AdTracking tracking;
  
  /// Ad priority for ordering (higher = more important)
  final int priority;
  
  /// Active date range
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  
  /// Target audience/location
  final String? target;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  Ad({
    required this.id,
    required this.name,
    this.description,
    required this.imageVariants,
    this.cta,
    required this.tracking,
    this.priority = 0,
    this.startDate,
    this.endDate,
    this.target,
    this.metadata,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => _$AdFromJson(json);
  Map<String, dynamic> toJson() => _$AdToJson(this);
  
  /// Check if the ad is currently active
  bool get isActive {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
  
  /// Get the best image variant for the given pixel ratio
  AdImageVariant getImageVariant(double pixelRatio) {
    // Default to the first variant if none match
    if (imageVariants.isEmpty) {
      throw Exception('No image variants available for ad $id');
    }
    
    // Find the best matching density
    // Sort by density and find the closest match (prefer higher density)
    final sorted = List<AdImageVariant>.from(imageVariants)
      ..sort((a, b) => a.density.compareTo(b.density));
    
    AdImageVariant? bestMatch;
    for (final variant in sorted) {
      if (variant.density >= pixelRatio) {
        bestMatch = variant;
        break;
      }
    }
    
    // If no higher density found, use the highest available
    return bestMatch ?? sorted.last;
  }
}

/// Image variant for different screen densities
@JsonSerializable()
class AdImageVariant {
  /// Image URL
  @JsonKey(name: 'image_url')
  final String imageUrl;
  
  /// Density multiplier (1.0 = mdpi, 1.5 = hdpi, 2.0 = xhdpi, 3.0 = xxhdpi, etc.)
  final double density;
  
  /// Image dimensions
  final int width;
  final int height;
  
  /// File size in bytes (optional, for bandwidth optimization)
  @JsonKey(name: 'file_size')
  final int? fileSize;

  AdImageVariant({
    required this.imageUrl,
    required this.density,
    required this.width,
    required this.height,
    this.fileSize,
  });

  factory AdImageVariant.fromJson(Map<String, dynamic> json) => 
      _$AdImageVariantFromJson(json);
  Map<String, dynamic> toJson() => _$AdImageVariantToJson(this);
}

/// Call-to-action button configuration
@JsonSerializable()
class AdCTA {
  /// Button text
  final String text;
  
  /// Target URL or deep link
  @JsonKey(name: 'target_url')
  final String targetUrl;
  
  /// Type: 'internal' for deep link, 'external' for web URL
  final String type;
  
  /// Normalized position (0.0 to 1.0) relative to ad container
  final AdPosition position;
  
  /// Button style configuration
  final AdCTAStyle style;

  AdCTA({
    required this.text,
    required this.targetUrl,
    required this.type,
    required this.position,
    required this.style,
  });

  factory AdCTA.fromJson(Map<String, dynamic> json) => _$AdCTAFromJson(json);
  Map<String, dynamic> toJson() => _$AdCTAToJson(this);
  
  /// Check if this is an internal deep link
  bool get isInternal => type.toLowerCase() == 'internal';
  
  /// Check if this is an external URL
  bool get isExternal => type.toLowerCase() == 'external';
}

/// Normalized position for CTA placement
@JsonSerializable()
class AdPosition {
  /// Horizontal position (0.0 = left, 1.0 = right)
  final double x;
  
  /// Vertical position (0.0 = top, 1.0 = bottom)
  final double y;
  
  /// Alignment: 'start', 'center', 'end'
  final String? alignment;

  AdPosition({
    required this.x,
    required this.y,
    this.alignment,
  });

  factory AdPosition.fromJson(Map<String, dynamic> json) => 
      _$AdPositionFromJson(json);
  Map<String, dynamic> toJson() => _$AdPositionToJson(this);
}

/// CTA button style configuration
@JsonSerializable()
class AdCTAStyle {
  /// Background color in hex format (e.g., "#FF5733")
  @JsonKey(name: 'background_color')
  final String? backgroundColor;
  
  /// Text color in hex format
  @JsonKey(name: 'text_color')
  final String? textColor;
  
  /// Border radius
  @JsonKey(name: 'border_radius')
  final double? borderRadius;
  
  /// Padding (in logical pixels)
  final double? padding;
  
  /// Font size
  @JsonKey(name: 'font_size')
  final double? fontSize;
  
  /// Font weight: 'normal', 'bold', '100'-'900'
  @JsonKey(name: 'font_weight')
  final String? fontWeight;
  
  /// Border configuration
  final AdBorder? border;
  
  /// Shadow configuration
  final AdShadow? shadow;

  AdCTAStyle({
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.border,
    this.shadow,
  });

  factory AdCTAStyle.fromJson(Map<String, dynamic> json) => 
      _$AdCTAStyleFromJson(json);
  Map<String, dynamic> toJson() => _$AdCTAStyleToJson(this);
}

/// Border configuration
@JsonSerializable()
class AdBorder {
  /// Border color in hex format
  final String color;
  
  /// Border width
  final double width;

  AdBorder({
    required this.color,
    required this.width,
  });

  factory AdBorder.fromJson(Map<String, dynamic> json) => 
      _$AdBorderFromJson(json);
  Map<String, dynamic> toJson() => _$AdBorderToJson(this);
}

/// Shadow configuration
@JsonSerializable()
class AdShadow {
  /// Shadow color in hex format with alpha
  final String color;
  
  /// Blur radius
  @JsonKey(name: 'blur_radius')
  final double blurRadius;
  
  /// Offset X
  @JsonKey(name: 'offset_x')
  final double offsetX;
  
  /// Offset Y
  @JsonKey(name: 'offset_y')
  final double offsetY;

  AdShadow({
    required this.color,
    required this.blurRadius,
    required this.offsetX,
    required this.offsetY,
  });

  factory AdShadow.fromJson(Map<String, dynamic> json) => 
      _$AdShadowFromJson(json);
  Map<String, dynamic> toJson() => _$AdShadowToJson(this);
}

/// Tracking URLs configuration
@JsonSerializable()
class AdTracking {
  /// Impression tracking endpoint
  @JsonKey(name: 'impression_url')
  final String? impressionUrl;
  
  /// Click tracking endpoint
  @JsonKey(name: 'click_url')
  final String? clickUrl;
  
  /// Additional tracking pixels
  final List<String>? pixels;

  AdTracking({
    this.impressionUrl,
    this.clickUrl,
    this.pixels,
  });

  factory AdTracking.fromJson(Map<String, dynamic> json) => 
      _$AdTrackingFromJson(json);
  Map<String, dynamic> toJson() => _$AdTrackingToJson(this);
}
