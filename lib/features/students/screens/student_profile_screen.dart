import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/attendance.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/student_repository.dart';
import '../repositories/batch_repository.dart';
import '../../fees/repositories/payment_repository.dart';

final studentBatchProvider = FutureProvider.family.autoDispose<Batch?, String?>((ref, batchId) async {
  if (batchId == null) return null;
  final repo = ref.watch(batchRepositoryProvider);
  final batches = await repo.getBatches();
  final match = batches.where((b) => b.id == batchId).toList();
  return match.isNotEmpty ? match.first : null;
});

final studentPaymentsHistoryProvider = FutureProvider.family.autoDispose<List<Payment>, String>((ref, studentId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return await repo.getStudentPayments(studentId);
});

final studentAttendanceLogsProvider = FutureProvider.family.autoDispose<List<Attendance>, String>((ref, studentId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('attendance')
      .select('*, profiles!inner(full_name)')
      .eq('student_id', studentId)
      .order('date', ascending: false);
  return (response as List).map((json) => Attendance.fromJson(json)).toList();
});

class StudentProfileScreen extends ConsumerWidget {
  final Student student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;
    final isRestrictedCoach = profile.isCoach && !profile.isActive;
    
    final batchAsync = ref.watch(studentBatchProvider(student.batchId));
    final paymentsAsync = ref.watch(studentPaymentsHistoryProvider(student.id));
    final attendanceAsync = ref.watch(studentAttendanceLogsProvider(student.id));

    final sportColor = student.sport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          if (profile.isAdmin || profile.isCoach)
            TextButton.icon(
              icon: Icon(Icons.edit_outlined, size: 18, color: isRestrictedCoach ? AppTheme.textMuted : AppTheme.accentLime),
              label: Text(
                isRestrictedCoach ? 'Edit (Restricted)' : 'Edit',
                style: TextStyle(color: isRestrictedCoach ? AppTheme.textMuted : AppTheme.accentLime),
              ),
              onPressed: isRestrictedCoach
                  ? null
                  : () async {
                      await context.push('/students/edit', extra: student);
                      // Invalidate data
                      ref.invalidate(studentBatchProvider(student.batchId));
                      ref.invalidate(studentPaymentsHistoryProvider(student.id));
                      ref.invalidate(studentAttendanceLogsProvider(student.id));
                    },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            _buildProfileHeader(ref, sportColor),
            const SizedBox(height: 20),

            // Parent contact information
            _buildContactInfo(context),
            const SizedBox(height: 20),

            // Batch information
            batchAsync.when(
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (err, stack) => Text('Error loading batch: $err'),
              data: (batch) => _buildBatchInfo(batch, sportColor),
            ),
            const SizedBox(height: 20),

            // Attendance rate log details
            attendanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading attendance: $err'),
              data: (logs) => _buildAttendanceSummary(logs),
            ),
            const SizedBox(height: 20),

            // Payments registry (For admins only)
            if (profile.isAdmin) ...[
              paymentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading payments: $err'),
                data: (payments) => _buildPaymentsRegistry(payments, currencyFormat),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(WidgetRef ref, Color sportColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          _buildPhoto(ref, sportColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  student.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (student.age != null) ...[
                      _infoPill('Age ${student.age}', AppTheme.textSecondary),
                      const SizedBox(width: 8),
                    ],
                    _infoPill(student.sport.toUpperCase(), sportColor, isBold: true),
                    const SizedBox(width: 8),
                    _infoPill(
                      student.status.toUpperCase(),
                      student.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Joined: ${DateFormat('dd MMM yyyy').format(student.joinDate)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(WidgetRef ref, Color fallbackColor) {
    if (student.photoUrl == null || student.photoUrl!.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: fallbackColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fallbackColor.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.person_rounded, color: fallbackColor, size: 40),
      );
    }

    final bytesAsync = ref.watch(studentPhotoBytesProvider(student.photoUrl!));
    return bytesAsync.when(
      data: (bytes) => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          border: Border.all(color: fallbackColor.withValues(alpha: 0.3)),
        ),
      ),
      loading: () => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime)),
      ),
      error: (err, stack) => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 30),
      ),
    );
  }

  Widget _infoPill(String text, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parent / Guardian Information',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Parent Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  SelectableText(
                    student.parentName ?? 'Not specified',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (student.phone != null)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, color: AppTheme.accentLime),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Simulated call to ${student.phone}')),
                        );
                      },
                      tooltip: 'Call parent',
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: AppTheme.accentTeal),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Simulated SMS to ${student.phone}')),
                        );
                      },
                      tooltip: 'SMS parent',
                    ),
                  ],
                ),
            ],
          ),
          if (student.phone != null) ...[
            const SizedBox(height: 12),
            const Text('Contact Phone', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            SelectableText(
              student.phone!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchInfo(Batch? batch, Color sportColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batch Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const Divider(height: 20),
          if (batch != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Batch Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(batch.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sportColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sportColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    batch.sport.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sportColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule Days', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      batch.days.isNotEmpty ? batch.days.join(', ') : 'None',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Timings', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      batch.startTime != null && batch.endTime != null
                          ? '${batch.startTime} - ${batch.endTime}'
                          : 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Student not assigned to any batch.', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(List<Attendance> logs) {
    final presentCount = logs.where((l) => l.status == 'present').length;
    final totalCount = logs.length;
    final double rate = totalCount > 0 ? presentCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Logs',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              if (totalCount > 0)
                Text(
                  'Rate: ${(rate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rate >= 0.75
                        ? AppTheme.successGreen
                        : (rate >= 0.5 ? AppTheme.warningAmber : AppTheme.errorRed),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),
          if (totalCount > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 8,
                      color: rate >= 0.75
                          ? AppTheme.successGreen
                          : (rate >= 0.5 ? AppTheme.warningAmber : AppTheme.errorRed),
                      backgroundColor: AppTheme.darkBorder,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$presentCount / $totalCount present', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                itemCount: logs.length > 5 ? 5 : logs.length, // Show recent 5 logs
                separatorBuilder: (context, index) => const Divider(height: 8, color: AppTheme.darkBorder),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isPresent = log.status == 'present';

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy').format(log.date), style: const TextStyle(fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPresent ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No attendance records logged.', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsRegistry(List<Payment> payments, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Registry',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const Divider(height: 20),
          if (payments.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (context, index) => const Divider(height: 8, color: AppTheme.darkBorder),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final monthName = DateFormat('MMMM').format(DateTime(2020, p.month));

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currencyFormat.format(p.amount)} - ${p.mode.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text('For $monthName ${p.year}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                      Text(DateFormat('dd MMM yyyy').format(p.paymentDate), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  );
                },
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No payments recorded yet.', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}
