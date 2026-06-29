class Batch {
  final String id;
  final String name;
  final String sport; // 'cricket' | 'football'
  final String? coachId;
  final int capacity;
  final List<String> days;
  final String? startTime;
  final String? endTime;
  final DateTime createdAt;

  Batch({
    required this.id,
    required this.name,
    required this.sport,
    this.coachId,
    required this.capacity,
    required this.days,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String,
      coachId: json['coach_id'] as String?,
      capacity: json['capacity'] as int? ?? 20,
      days: json['days'] != null ? (json['days'] as List).cast<String>() : [],
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'coach_id': coachId,
      'capacity': capacity,
      'days': days,
      'start_time': startTime,
      'end_time': endTime,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Batch copyWith({
    String? id,
    String? name,
    String? sport,
    String? coachId,
    int? capacity,
    List<String>? days,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      coachId: coachId ?? this.coachId,
      capacity: capacity ?? this.capacity,
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

