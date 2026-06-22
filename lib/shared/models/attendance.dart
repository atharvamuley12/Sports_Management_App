class Attendance {
  final String id;
  final String studentId;
  final DateTime date;
  final String status; // 'present' | 'absent'
  final String markedBy;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      markedBy: json['marked_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'status': status,
      'marked_by': markedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  Attendance copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    String? status,
    String? markedBy,
    DateTime? createdAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
