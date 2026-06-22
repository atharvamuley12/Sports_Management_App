class Batch {
  final String id;
  final String name;
  final String sport; // 'cricket' | 'football'
  final String? coachId;
  final DateTime createdAt;

  Batch({
    required this.id,
    required this.name,
    required this.sport,
    this.coachId,
    required this.createdAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String,
      coachId: json['coach_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'coach_id': coachId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Batch copyWith({
    String? id,
    String? name,
    String? sport,
    String? coachId,
    DateTime? createdAt,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      coachId: coachId ?? this.coachId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
