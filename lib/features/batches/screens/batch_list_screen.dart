import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/repositories/profile_repository.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';
import '../../../core/utils/export_helper.dart';

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Batches',
            onSelected: (value) async {
              final batches = batchesAsync.value ?? [];
              final coaches = coachesAsync.value ?? {};
              final counts = countsAsync.value ?? {};
              final headers = ['Batch Name', 'Sport', 'Days', 'Capacity', 'Coach Name', 'Student Count'];
              final rows = batches.map((b) {
                final coachName = b.coachId != null ? (coaches[b.coachId] ?? 'Unknown Coach') : 'Unassigned';
                final studentCount = counts[b.id] ?? 0;
                return [
                  b.name,
                  b.sport,
                  b.days.join(', '),
                  b.capacity.toString(),
                  coachName,
                  studentCount.toString(),
                ];
              }).toList();

              final isPdf = value.endsWith('pdf');
              final isShare = value.startsWith('share');

              await ExportHelper.exportData(
                context: context,
                fileName: 'batches_report',
                title: 'Batches List',
                headers: headers,
                rows: rows,
                exportAsPdf: isPdf,
                share: isShare,
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: AppTheme.errorRed, size: 18),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_pdf',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppTheme.errorRed, size: 18),
                    SizedBox(width: 8),
                    Text('Share PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download_excel',
                child: Row(
                  children: [
                    Icon(Icons.grid_on_rounded, color: AppTheme.successGreen, size: 18),
                    SizedBox(width: 8),
                    Text('Download Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_excel',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppTheme.successGreen, size: 18),
                    SizedBox(width: 8),
                    Text('Share Excel'),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space12),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.limeGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
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
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accentLime,
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          ref.invalidate(batchesListProvider);
          ref.invalidate(batchCoachesMapProvider);
          ref.invalidate(batchStudentCountsProvider);
        },
        child: batchesAsync.when(
          loading: () => const AppLoadingState(itemCount: 4, itemHeight: 140),
          error: (err, stack) => AppErrorState(
            message: err.toString(),
            onRetry: () {
              ref.invalidate(batchesListProvider);
              ref.invalidate(batchCoachesMapProvider);
              ref.invalidate(batchStudentCountsProvider);
            },
          ),
          data: (batches) {
            if (batches.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.layers_clear_outlined,
                    title: 'No batches created yet',
                    subtitle: 'Create a new batch using the "+" button on the top right.',
                  ),
                ],
              );
            }

            final coaches = coachesAsync.value ?? {};
            final counts = countsAsync.value ?? {};

            return ListView.builder(
              itemCount: batches.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemBuilder: (context, index) {
                final batch = batches[index];
                final coachName = batch.coachId != null ? (coaches[batch.coachId] ?? 'Unknown Coach') : 'Unassigned';
                final studentCount = counts[batch.id] ?? 0;
                final isFull = studentCount >= batch.capacity;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final sportLower = batch.sport.toLowerCase();
                Color sportColor = sportLower == 'cricket'
                    ? AppTheme.accentLime
                    : (sportLower == 'chess' ? AppTheme.accentPurple : AppTheme.accentTeal);
                if (!isDark) {
                  if (sportColor == AppTheme.accentLime) {
                    sportColor = AppTheme.accentLimeDark;
                  } else if (sportColor == AppTheme.accentTeal) {
                    sportColor = AppTheme.accentTealDark;
                  } else if (sportColor == AppTheme.accentPurple) {
                    sportColor = AppTheme.accentPurpleDark;
                  }
                }
                final gradient = sportLower == 'cricket'
                    ? AppTheme.limeGradient
                    : (sportLower == 'chess' ? AppTheme.purpleGradient : AppTheme.tealGradient);
                final capacityRatio = batch.capacity > 0 ? studentCount / batch.capacity : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space14),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    onTap: () async {
                      await context.push('/batches/edit', extra: batch);
                      ref.invalidate(batchesListProvider);
                      ref.invalidate(batchStudentCountsProvider);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppGradientIcon(
                              icon: sportLower == 'cricket'
                                  ? Icons.sports_cricket
                                  : (sportLower == 'chess' ? Icons.grid_on : Icons.sports_soccer),
                              gradient: gradient,
                              size: 18,
                              padding: AppTheme.space8,
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    batch.name,
                                    style: AppTheme.subtitle1,
                                  ),
                                  const SizedBox(height: AppTheme.space2),
                                  Text(
                                    'Coach: $coachName',
                                    style: AppTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                          ],
                        ),
                        const Divider(height: AppTheme.space24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Days', style: AppTheme.caption),
                                  const SizedBox(height: AppTheme.space2),
                                  Text(
                                    batch.days.isNotEmpty ? batch.days.join(', ') : 'None selected',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: AppTheme.space12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Enrollment', style: AppTheme.caption),
                                const SizedBox(height: AppTheme.space2),
                                Text(
                                  '$studentCount / ${batch.capacity}',
                                  style: AppTheme.subtitle2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isFull ? AppTheme.errorRed : AppTheme.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radius6),
                          child: LinearProgressIndicator(
                            value: capacityRatio.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder,
                            valueColor: AlwaysStoppedAnimation(isFull ? AppTheme.errorRed : sportColor),
                          ),
                        ),
                      ],
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
