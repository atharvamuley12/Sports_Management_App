class Activity {
  final String id;
  final String coachId;
  final String coachName;
  final DateTime date;
  final String title;
  final String description;
  final DateTime createdAt;
  final String status; // 'planned', 'completed', 'cancelled'

  Activity({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.date,
    required this.title,
    required this.description,
    required this.createdAt,
    this.status = 'planned',
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      coachName: json['coach_name'] as String? ?? 'Unknown Coach',
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'planned',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'date': date.toIso8601String().split('T')[0],
      'title': title,
      'description': description,
      'status': status,
    };
  }

  Activity copyWith({
    String? id,
    String? coachId,
    String? coachName,
    DateTime? date,
    String? title,
    String? description,
    DateTime? createdAt,
    String? status,
  }) {
    return Activity(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
