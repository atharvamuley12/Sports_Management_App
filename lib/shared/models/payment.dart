class Payment {
  final String id;
  final String studentId;
  final double amount;
  final DateTime paymentDate;
  final int month;
  final int year;
  final String mode; // 'cash' | 'upi'
  final String recordedBy;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.month,
    required this.year,
    required this.mode,
    required this.recordedBy,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      month: json['month'] as int,
      year: json['year'] as int,
      mode: json['mode'] as String,
      recordedBy: json['recorded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'payment_date': "${paymentDate.year.toString().padLeft(4, '0')}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}",
      'month': month,
      'year': year,
      'mode': mode,
      'recorded_by': recordedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? studentId,
    double? amount,
    DateTime? paymentDate,
    int? month,
    int? year,
    String? mode,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      month: month ?? this.month,
      year: year ?? this.year,
      mode: mode ?? this.mode,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model for the calculated pending dues of a student.
class StudentDues {
  final String studentId;
  final String name;
  final double monthlyFee;
  final DateTime joinDate;
  final String status;
  final String? batchId;
  final int monthsSinceJoin;
  final double expectedFees;
  final double totalPaid;
  final double pendingDues;

  StudentDues({
    required this.studentId,
    required this.name,
    required this.monthlyFee,
    required this.joinDate,
    required this.status,
    this.batchId,
    required this.monthsSinceJoin,
    required this.expectedFees,
    required this.totalPaid,
    required this.pendingDues,
  });

  factory StudentDues.fromJson(Map<String, dynamic> json) {
    return StudentDues(
      studentId: json['student_id'] as String,
      name: json['name'] as String,
      monthlyFee: (json['monthly_fee'] as num).toDouble(),
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String,
      batchId: json['batch_id'] as String?,
      monthsSinceJoin: json['months_since_join'] as int,
      expectedFees: (json['expected_fees'] as num).toDouble(),
      totalPaid: (json['total_paid'] as num).toDouble(),
      pendingDues: (json['pending_dues'] as num).toDouble(),
    );
  }
}
