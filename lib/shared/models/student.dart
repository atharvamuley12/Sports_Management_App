class Student {
  final String id;
  final String name;
  final String? parentName;
  final String? phone;
  final int? age;
  final String sport; // 'cricket' | 'football'
  final String? batchId;
  final double monthlyFee;
  final DateTime joinDate;
  final String status; // 'active' | 'inactive'
  final String? photoUrl;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    this.parentName,
    this.phone,
    this.age,
    required this.sport,
    this.batchId,
    required this.monthlyFee,
    required this.joinDate,
    required this.status,
    this.photoUrl,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      parentName: json['parent_name'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] as int?,
      sport: json['sport'] as String,
      batchId: json['batch_id'] as String?,
      monthlyFee: (json['monthly_fee'] as num).toDouble(),
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String? ?? 'active',
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_name': parentName,
      'phone': phone,
      'age': age,
      'sport': sport,
      'batch_id': batchId,
      'monthly_fee': monthlyFee,
      'join_date': "${joinDate.year.toString().padLeft(4, '0')}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}",
      'status': status,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';

  Student copyWith({
    String? id,
    String? name,
    String? parentName,
    String? phone,
    int? age,
    String? sport,
    String? batchId,
    double? monthlyFee,
    DateTime? joinDate,
    String? status,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      parentName: parentName ?? this.parentName,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      sport: sport ?? this.sport,
      batchId: batchId ?? this.batchId,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
