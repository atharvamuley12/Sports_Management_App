class Expense {
  final String id;
  final String category; // 'cricket_pitch' | 'football_ground' | 'equipment' | 'shed_construction' | 'maintenance' | 'salary' | 'misc'
  final double amount;
  final DateTime date;
  final String? description;
  final String? receiptUrl;
  final String recordedBy;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.receiptUrl,
    required this.recordedBy,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      recordedBy: json['recorded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'description': description,
      'receipt_url': receiptUrl,
      'recorded_by': recordedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? category,
    double? amount,
    DateTime? date,
    String? description,
    String? receiptUrl,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
