import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/batch.dart';
import '../../auth/repositories/profile_repository.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';

final batchesListProvider = FutureProvider.autoDispose<List<Batch>>((ref) async {
  final repo = ref.watch(batchRepositoryProvider);
  return await repo.getBatches();
});

final batchCoachesMapProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final coaches = await repo.getCoaches();
  return {for (var c in coaches) c.id: c.fullName};
});

final batchStudentCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final students = await repo.getStudents();
  final Map<String, int> counts = {};
  for (var s in students) {
    if (s.batchId != null) {
      counts[s.batchId!] = (counts[s.batchId!] ?? 0) + 1;
    }
  }
  return counts;
});

class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchesListProvider);
    final coachesAsync = ref.watch(batchCoachesMapProvider);
    final countsAsync = ref.watch(batchStudentCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batches'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.limeGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.black),
              onPressed: () async {
                await context.push('/batches/new');
                ref.invalidate(batchesListProvider);
                ref.invalidate(batchStudentCountsProvider);
              },
              tooltip: 'Create Batch',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accentLime,
        onRefresh: () async {
          ref.invalidate(batchesListProvider);
          ref.invalidate(batchCoachesMapProvider);
          ref.invalidate(batchStudentCountsProvider);
        },
        child: batchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentLime, strokeWidth: 2.5)),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorRed),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Error loading batches: $err',
                    style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (batches) {
            if (batches.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.layers_clear_outlined, size: 56, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No batches created yet',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final coaches = coachesAsync.value ?? {};
            final counts = countsAsync.value ?? {};

            return ListView.builder(
              itemCount: batches.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final batch = batches[index];
                final coachName = batch.coachId != null ? (coaches[batch.coachId] ?? 'Unknown Coach') : 'Unassigned';
                final studentCount = counts[batch.id] ?? 0;
                final isFull = studentCount >= batch.capacity;
                final sportColor = batch.sport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () async {
                        await context.push('/batches/edit', extra: batch);
                        ref.invalidate(batchesListProvider);
                        ref.invalidate(batchStudentCountsProvider);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: sportColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    batch.sport == 'cricket' ? Icons.sports_cricket : Icons.sports_soccer,
                                    color: sportColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        batch.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Coach: $coachName',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Days', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      batch.days.isNotEmpty ? batch.days.join(', ') : 'None selected',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Timings', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      batch.startTime != null && batch.endTime != null
                                          ? '${batch.startTime} - ${batch.endTime}'
                                          : 'N/A',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Enrollment', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$studentCount / ${batch.capacity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isFull ? AppTheme.errorRed : AppTheme.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
