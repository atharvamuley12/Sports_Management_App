import 'package:supabase_flutter/supabase_flutter.dart';

class SeedHelper {
  /// Seeds test data into the database under the current authenticated user's id.
  static Future<void> seedTestData(SupabaseClient supabase) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user found to record logs.');

    // 1. Create Batches
    final batchCricketRes = await supabase.from('batches').insert({
      'name': 'Cricket Junior Stars',
      'sport': 'cricket',
      'coach_id': null,
    }).select().single();

    final batchFootballRes = await supabase.from('batches').insert({
      'name': 'Football Elite Academy',
      'sport': 'football',
      'coach_id': null,
    }).select().single();

    final cricketBatchId = batchCricketRes['id'];
    final footballBatchId = batchFootballRes['id'];

    // 2. Create Students
    final students = [
      {
        'name': 'Aarav Sharma',
        'parent_name': 'Rajesh Sharma',
        'phone': '9876543210',
        'age': 12,
        'sport': 'cricket',
        'batch_id': cricketBatchId,
        'monthly_fee': 1500.0,
        'join_date': '2026-04-01',
        'status': 'active',
      },
      {
        'name': 'Kabir Singh',
        'parent_name': 'Manpreet Singh',
        'phone': '9812345678',
        'age': 14,
        'sport': 'cricket',
        'batch_id': cricketBatchId,
        'monthly_fee': 1500.0,
        'join_date': '2026-05-15',
        'status': 'active',
      },
      {
        'name': 'Rohan Das',
        'parent_name': 'Amit Das',
        'phone': '9823456789',
        'age': 15,
        'sport': 'football',
        'batch_id': footballBatchId,
        'monthly_fee': 1200.0,
        'join_date': '2026-04-10',
        'status': 'active',
      },
      {
        'name': 'Anya Iyer',
        'parent_name': 'Subramanian Iyer',
        'phone': '9945678123',
        'age': 11,
        'sport': 'football',
        'batch_id': footballBatchId,
        'monthly_fee': 1200.0,
        'join_date': '2026-05-01',
        'status': 'active',
      },
    ];

    final insertedStudents = await supabase.from('students').insert(students).select();

    // Find Aarav and Rohan's IDs to record payments
    final aarav = (insertedStudents as List).firstWhere((s) => s['name'] == 'Aarav Sharma');
    final rohan = insertedStudents.firstWhere((s) => s['name'] == 'Rohan Das');

    // 3. Create Payments
    await supabase.from('payments').insert([
      {
        'student_id': aarav['id'],
        'amount': 1500.0,
        'payment_date': '2026-04-05',
        'month': 4,
        'year': 2026,
        'mode': 'cash',
        'recorded_by': currentUser.id,
      },
      {
        'student_id': aarav['id'],
        'amount': 1500.0,
        'payment_date': '2026-05-07',
        'month': 5,
        'year': 2026,
        'mode': 'upi',
        'recorded_by': currentUser.id,
      },
      {
        'student_id': rohan['id'],
        'amount': 1200.0,
        'payment_date': '2026-04-12',
        'month': 4,
        'year': 2026,
        'mode': 'upi',
        'recorded_by': currentUser.id,
      },
    ]);

    // 4. Create Expenses
    await supabase.from('expenses').insert([
      {
        'category': 'equipment',
        'amount': 3500.0,
        'date': '2026-04-15',
        'description': 'Purchased cricket leather balls and football pumps',
        'recorded_by': currentUser.id,
      },
      {
        'category': 'cricket_pitch',
        'amount': 5000.0,
        'date': '2026-05-10',
        'description': 'Cricket clay pitch rolling and levelling',
        'recorded_by': currentUser.id,
      },
    ]);
  }
}
