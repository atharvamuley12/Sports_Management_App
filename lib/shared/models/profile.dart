class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String role; // 'admin' | 'coach'
  final bool isActive;
  final bool mustChangePassword;
  final DateTime createdAt;
  final String? degree;
  final String? experience;
  final String? speciality;
  final String? achievements;
  final String? photoUrl;

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    required this.createdAt,
    this.degree,
    this.experience,
    this.speciality,
    this.achievements,
    this.photoUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      degree: json['degree'] as String?,
      experience: json['experience'] as String?,
      speciality: json['speciality'] as String?,
      achievements: json['achievements'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
      'created_at': createdAt.toIso8601String(),
      'degree': degree,
      'experience': experience,
      'speciality': speciality,
      'achievements': achievements,
      'photo_url': photoUrl,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isCoach => role == 'coach';

  Profile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? role,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? createdAt,
    String? degree,
    String? experience,
    String? speciality,
    String? achievements,
    String? photoUrl,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      degree: degree ?? this.degree,
      experience: experience ?? this.experience,
      speciality: speciality ?? this.speciality,
      achievements: achievements ?? this.achievements,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
