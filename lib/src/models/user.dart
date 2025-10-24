import 'dart:convert';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? country;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? emailVerifiedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.country,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.emailVerifiedAt,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at'] as String) 
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'country': country,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
    };
  }

  /// Create User copy with modified fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? country,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? emailVerifiedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  /// Convert User to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create User from JSON string
  factory User.fromJsonString(String jsonString) {
    return User.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return this.role == role;
  }

  /// Check if user is customer
  bool get isCustomer => role == 'customer';

  /// Check if user is partner
  bool get isPartner => role == 'partner';

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Get display name for role
  String get roleDisplayName {
    switch (role) {
      case 'customer':
        return 'Customer';
      case 'partner':
        return 'Partner';
      case 'admin':
        return 'Administrator';
      default:
        return 'Unknown';
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
