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
import '../../../shared/widgets/app_widgets.dart';
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
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space12),
              child: TextButton.icon(
                icon: Icon(
                  Icons.edit_outlined, 
                  size: 18, 
                  color: isRestrictedCoach ? AppTheme.textMuted : AppTheme.accentLime,
                ),
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
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            _buildProfileHeader(ref, sportColor),
            const SizedBox(height: AppTheme.space16),

            // Parent contact information
            _buildContactInfo(context),
            const SizedBox(height: AppTheme.space16),

            // Batch information
            batchAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: SizedBox(height: 2, child: LinearProgressIndicator()),
              )),
              error: (err, stack) => AppErrorState(message: 'Error loading batch: $err'),
              data: (batch) => _buildBatchInfo(batch, sportColor),
            ),
            const SizedBox(height: AppTheme.space16),

            // Attendance rate log details
            attendanceAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppTheme.space16),
                child: SizedBox(height: 2, child: LinearProgressIndicator()),
              )),
              error: (err, stack) => AppErrorState(message: 'Error loading attendance: $err'),
              data: (logs) => _buildAttendanceSummary(logs),
            ),
            const SizedBox(height: AppTheme.space16),

            // Payments registry (For admins only)
            if (profile.isAdmin) ...[
              paymentsAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(AppTheme.space16),
                  child: SizedBox(height: 2, child: LinearProgressIndicator()),
                )),
                error: (err, stack) => AppErrorState(message: 'Error loading payments: $err'),
                data: (payments) => _buildPaymentsRegistry(payments, currencyFormat),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(WidgetRef ref, Color sportColor) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Row(
        children: [
          _buildPhoto(ref, sportColor),
          const SizedBox(width: AppTheme.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  student.name,
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: AppTheme.space6),
                Wrap(
                  spacing: AppTheme.space6,
                  runSpacing: AppTheme.space6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (student.age != null)
                      _infoPill('Age ${student.age}', AppTheme.textSecondary),
                    AppStatusChip.sport(student.sport),
                    student.isActive ? AppStatusChip.active() : AppStatusChip.inactive(),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: AppTheme.space4),
                    SelectableText(
                      'Joined: ${DateFormat('dd MMM yyyy').format(student.joinDate)}',
                      style: AppTheme.caption,
                    ),
                  ],
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
          color: fallbackColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          border: Border.all(color: fallbackColor.withValues(alpha: 0.15)),
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
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          border: Border.all(color: AppTheme.darkBorder),
        ),
      ),
      loading: () => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
        ),
        child: const Center(child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
        )),
      ),
      error: (err, stack) => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius20),
        ),
        child: const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 30),
      ),
    );
  }

  Widget _infoPill(String text, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius6),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        text,
        style: AppTheme.overline.copyWith(
          fontSize: 9,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'PARENT / GUARDIAN INFORMATION',
            icon: Icons.family_restroom_rounded,
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parent Name', style: AppTheme.caption),
                  const SizedBox(height: AppTheme.space2),
                  SelectableText(
                    student.parentName ?? 'Not specified',
                    style: AppTheme.subtitle1,
                  ),
                ],
              ),
              if (student.phone != null && student.phone!.isNotEmpty)
                Row(
                  children: [
                    AppIconButton(
                      icon: Icons.call_rounded,
                      color: AppTheme.accentLime,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Simulated call to ${student.phone}')),
                        );
                      },
                      tooltip: 'Call parent',
                    ),
                    const SizedBox(width: AppTheme.space8),
                    AppIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppTheme.accentTeal,
                      onTap: () {
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
          if (student.phone != null && student.phone!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Text('Contact Phone', style: AppTheme.caption),
            const SizedBox(height: AppTheme.space2),
            SelectableText(
              student.phone!,
              style: AppTheme.subtitle1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchInfo(Batch? batch, Color sportColor) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'BATCH DETAILS',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: AppTheme.space12),
          if (batch != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batch Name', style: AppTheme.caption),
                    const SizedBox(height: AppTheme.space2),
                    Text(batch.name, style: AppTheme.subtitle1),
                  ],
                ),
                AppStatusChip.sport(batch.sport),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule Days', style: AppTheme.caption),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        batch.days.isNotEmpty ? batch.days.join(', ') : 'None',
                        style: AppTheme.subtitle2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Timings', style: AppTheme.caption),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        batch.startTime != null && batch.endTime != null
                            ? '${batch.startTime} - ${batch.endTime}'
                            : 'N/A',
                        style: AppTheme.subtitle2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
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
    final Color rateColor = rate >= 0.75
        ? AppTheme.successGreen
        : (rate >= 0.5 ? AppTheme.warningAmber : AppTheme.errorRed);

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppSectionHeader(
                title: 'ATTENDANCE LOGS',
                icon: Icons.playlist_add_check_rounded,
              ),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space4),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                  ),
                  child: Text(
                    'Rate: ${(rate * 100).toStringAsFixed(1)}%',
                    style: AppTheme.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: rateColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          if (totalCount > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radius6),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      color: rateColor,
                      backgroundColor: AppTheme.darkBorder,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text('$presentCount / $totalCount present', style: AppTheme.caption),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                itemCount: logs.length > 5 ? 5 : logs.length, // Show recent 5 logs
                separatorBuilder: (context, index) => const Divider(height: AppTheme.space8),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isPresent = log.status == 'present';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: AppTheme.space6),
                            Text(
                              DateFormat('dd MMMM yyyy').format(log.date), 
                              style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        isPresent ? AppStatusChip.present() : AppStatusChip.absent(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
                child: Text('No attendance records logged.', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsRegistry(List<Payment> payments, NumberFormat currencyFormat) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'PAYMENT REGISTRY',
            icon: Icons.payments_rounded,
          ),
          const SizedBox(height: AppTheme.space12),
          if (payments.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (context, index) => const Divider(height: AppTheme.space8),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final monthName = DateFormat('MMMM').format(DateTime(2020, p.month));

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currencyFormat.format(p.amount)} - ${p.mode.toUpperCase()}',
                              style: AppTheme.subtitle2,
                            ),
                            Text(
                              'For $monthName ${p.year}', 
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: AppTheme.space4),
                            Text(
                              DateFormat('dd MMM yyyy').format(p.paymentDate), 
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
                child: Text('No payments recorded yet.', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}
