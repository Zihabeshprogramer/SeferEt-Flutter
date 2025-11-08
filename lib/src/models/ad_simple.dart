/// Represents an advertisement with images, CTA, and tracking configuration
class Ad {
  final String id;
  final String name;
  final String? description;
  
  /// Image variants for different densities
  final List<AdImageVariant> imageVariants;
  
  /// Call-to-action configuration
  final AdCTA? cta;
  
  /// Tracking configuration
  final AdTracking tracking;
  
  /// Ad priority for ordering (higher = more important)
  final int priority;
  
  /// Active date range
  final DateTime? startDate;
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

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageVariants: (json['image_variants'] as List<dynamic>?)
              ?.map((e) => AdImageVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cta: json['cta'] != null
          ? AdCTA.fromJson(json['cta'] as Map<String, dynamic>)
          : null,
      tracking: json['tracking_urls'] != null
          ? AdTracking.fromJson(json['tracking_urls'] as Map<String, dynamic>)
          : AdTracking(),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      target: json['target']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_variants': imageVariants.map((e) => e.toJson()).toList(),
      'cta': cta?.toJson(),
      'tracking_urls': tracking.toJson(),
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'target': target,
      'metadata': metadata,
    };
  }
  
  /// Check if the ad is currently active
  bool get isActive {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
  
  /// Get the best image variant for the given pixel ratio
  AdImageVariant getImageVariant(double pixelRatio) {
    if (imageVariants.isEmpty) {
      throw Exception('No image variants available for ad $id');
    }
    
    final sorted = List<AdImageVariant>.from(imageVariants)
      ..sort((a, b) => a.density.compareTo(b.density));
    
    AdImageVariant? bestMatch;
    for (final variant in sorted) {
      if (variant.density >= pixelRatio) {
        bestMatch = variant;
        break;
      }
    }
    
    return bestMatch ?? sorted.last;
  }
}

/// Image variant for different screen densities
class AdImageVariant {
  final String imageUrl;
  final double density;
  final int width;
  final int height;
  final int? fileSize;

  AdImageVariant({
    required this.imageUrl,
    required this.density,
    required this.width,
    required this.height,
    this.fileSize,
  });

  factory AdImageVariant.fromJson(Map<String, dynamic> json) {
    return AdImageVariant(
      imageUrl: json['image_url']?.toString() ?? '',
      density: (json['density'] as num?)?.toDouble() ?? 1.0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      fileSize: (json['file_size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'density': density,
      'width': width,
      'height': height,
      'file_size': fileSize,
    };
  }
}

/// Call-to-action button configuration
class AdCTA {
  final String text;
  final String targetUrl;
  final String type;
  final AdPosition position;
  final AdCTAStyle style;

  AdCTA({
    required this.text,
    required this.targetUrl,
    required this.type,
    required this.position,
    required this.style,
  });

  factory AdCTA.fromJson(Map<String, dynamic> json) {
    return AdCTA(
      text: json['text']?.toString() ?? '',
      targetUrl: json['target_url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'external',
      position: AdPosition.fromJson(
        json['position'] as Map<String, dynamic>? ?? {},
      ),
      style: AdCTAStyle.fromJson(
        json['style'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'target_url': targetUrl,
      'type': type,
      'position': position.toJson(),
      'style': style.toJson(),
    };
  }
  
  bool get isInternal => type.toLowerCase() == 'internal';
  bool get isExternal => type.toLowerCase() == 'external';
}

/// Normalized position for CTA placement
class AdPosition {
  final double x;
  final double y;
  final String? alignment;

  AdPosition({
    required this.x,
    required this.y,
    this.alignment,
  });

  factory AdPosition.fromJson(Map<String, dynamic> json) {
    return AdPosition(
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.8,
      alignment: json['alignment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'alignment': alignment,
    };
  }
}

/// CTA button style configuration
class AdCTAStyle {
  final String? backgroundColor;
  final String? textColor;
  final double? borderRadius;
  final double? padding;
  final double? fontSize;
  final String? fontWeight;
  final AdBorder? border;
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

  factory AdCTAStyle.fromJson(Map<String, dynamic> json) {
    return AdCTAStyle(
      backgroundColor: json['background_color']?.toString(),
      textColor: json['text_color']?.toString(),
      borderRadius: (json['border_radius'] as num?)?.toDouble(),
      padding: (json['padding'] as num?)?.toDouble(),
      fontSize: (json['font_size'] as num?)?.toDouble(),
      fontWeight: json['font_weight']?.toString(),
      border: json['border'] != null
          ? AdBorder.fromJson(json['border'] as Map<String, dynamic>)
          : null,
      shadow: json['shadow'] != null
          ? AdShadow.fromJson(json['shadow'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'background_color': backgroundColor,
      'text_color': textColor,
      'border_radius': borderRadius,
      'padding': padding,
      'font_size': fontSize,
      'font_weight': fontWeight,
      'border': border?.toJson(),
      'shadow': shadow?.toJson(),
    };
  }
}

/// Border configuration
class AdBorder {
  final String color;
  final double width;

  AdBorder({
    required this.color,
    required this.width,
  });

  factory AdBorder.fromJson(Map<String, dynamic> json) {
    return AdBorder(
      color: json['color']?.toString() ?? '#000000',
      width: (json['width'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'width': width,
    };
  }
}

/// Shadow configuration
class AdShadow {
  final String color;
  final double blurRadius;
  final double offsetX;
  final double offsetY;

  AdShadow({
    required this.color,
    required this.blurRadius,
    required this.offsetX,
    required this.offsetY,
  });

  factory AdShadow.fromJson(Map<String, dynamic> json) {
    return AdShadow(
      color: json['color']?.toString() ?? '#000000',
      blurRadius: (json['blur_radius'] as num?)?.toDouble() ?? 4.0,
      offsetX: (json['offset_x'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offset_y'] as num?)?.toDouble() ?? 2.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'blur_radius': blurRadius,
      'offset_x': offsetX,
      'offset_y': offsetY,
    };
  }
}

/// Tracking URLs configuration
class AdTracking {
  final String? impressionUrl;
  final String? clickUrl;
  final List<String>? pixels;

  AdTracking({
    this.impressionUrl,
    this.clickUrl,
    this.pixels,
  });

  factory AdTracking.fromJson(Map<String, dynamic> json) {
    return AdTracking(
      impressionUrl: json['impression_url']?.toString(),
      clickUrl: json['click_url']?.toString(),
      pixels: (json['pixels'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'impression_url': impressionUrl,
      'click_url': clickUrl,
      'pixels': pixels,
    };
  }
}
