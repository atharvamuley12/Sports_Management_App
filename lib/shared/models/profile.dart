class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String role; // 'admin' | 'coach'
  final bool isActive;
  final bool mustChangePassword;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isCoach => role == 'coach';

  Profile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? role,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
