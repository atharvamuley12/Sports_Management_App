import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/student_repository.dart';
import '../repositories/batch_repository.dart';

final studentListProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  final studentRepo = ref.watch(studentRepositoryProvider);
  return await studentRepo.getStudents();
});

final studentListBatchesProvider = FutureProvider.autoDispose<List<Batch>>((ref) async {
  final repo = ref.watch(batchRepositoryProvider);
  return await repo.getBatches();
});

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'all'; // 'all' | 'active' | 'inactive'
  String _selectedSportFilter = 'all'; // 'all' | 'cricket' | 'football'
  String? _selectedBatchIdFilter; // null = all

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;
    final studentListAsync = ref.watch(studentListProvider);

    final isRestrictedCoach = profile.isCoach && !profile.isActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          if ((profile.isAdmin || profile.isCoach) && !isRestrictedCoach)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.limeGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Colors.black),
                  onPressed: () async {
                    await context.push('/students/new');
                    ref.invalidate(studentListProvider);
                  },
                  tooltip: 'Add Student',
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space12, AppTheme.space16, AppTheme.space4),
            child: AppSearchBar(
              hint: 'Search by name or phone...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          
          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space4, AppTheme.space16, AppTheme.space8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDropdownFilter(
                    value: _selectedStatusFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatusFilter = val!;
                      });
                    },
                  ),
                  const SizedBox(width: AppTheme.space8),
                  _buildDropdownFilter(
                    value: _selectedSportFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Sports')),
                      DropdownMenuItem(value: 'cricket', child: Text('Cricket')),
                      DropdownMenuItem(value: 'football', child: Text('Football')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSportFilter = val!;
                      });
                    },
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Consumer(
                    builder: (context, ref, child) {
                      final batchesAsync = ref.watch(studentListBatchesProvider);
                      return batchesAsync.when(
                        data: (batches) {
                          return _buildDropdownFilter(
                            value: _selectedBatchIdFilter,
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('All Batches')),
                              ...batches.map((b) => DropdownMenuItem<String>(value: b.id, child: Text(b.name))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedBatchIdFilter = val;
                              });
                            },
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (err, stack) => const SizedBox(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.accentLime,
              backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              onRefresh: () async {
                ref.invalidate(studentListProvider);
              },
              child: studentListAsync.when(
                loading: () => const AppLoadingState(itemCount: 5, itemHeight: 92),
                error: (err, stack) => AppErrorState(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(studentListProvider),
                ),
                data: (students) {
                  final filtered = students.where((s) {
                    final matchesName = s.name.toLowerCase().contains(_searchQuery);
                    final matchesPhone = s.phone?.toLowerCase().contains(_searchQuery) ?? false;
                    final matchesSearch = matchesName || matchesPhone;
                    
                    final matchesStatus = _selectedStatusFilter == 'all' || s.status == _selectedStatusFilter;
                    final matchesSport = _selectedSportFilter == 'all' || s.sport == _selectedSportFilter;
                    final matchesBatch = _selectedBatchIdFilter == null || s.batchId == _selectedBatchIdFilter;

                    return matchesSearch && matchesStatus && matchesSport && matchesBatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        AppEmptyState(
                          icon: Icons.people_outline_rounded,
                          title: _searchQuery.isEmpty ? 'No students match filters' : 'No students found',
                          subtitle: _searchQuery.isEmpty
                              ? 'Try changing your status, sport, or batch filters above.'
                              : 'No students match your query "$_searchQuery".',
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return _buildStudentCard(context, ref, student);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          style: AppTheme.subtitle2.copyWith(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, Student student) {
    final sportColor = student.sport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space10),
      child: AppCard(
        padding: const EdgeInsets.all(AppTheme.space12),
        onTap: () async {
          await context.push('/students/profile', extra: student);
          ref.invalidate(studentListProvider);
        },
        child: Row(
          children: [
            _buildStudentPhoto(ref, student.photoUrl, sportColor),
            const SizedBox(width: AppTheme.space14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: AppTheme.subtitle1,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Row(
                    children: [
                      if (student.age != null)
                        _infoPill('Age ${student.age}', AppTheme.textMuted),
                      if (student.age != null) const SizedBox(width: AppTheme.space6),
                      AppStatusChip.sport(student.sport),
                    ],
                  ),
                  if (student.phone != null && student.phone!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space6),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          student.phone!,
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (student.isActive)
                  AppStatusChip.active()
                else
                  AppStatusChip.inactive(),
                const SizedBox(height: AppTheme.space14),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
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

  Widget _buildStudentPhoto(WidgetRef ref, String? path, Color fallbackColor) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: fallbackColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: fallbackColor.withValues(alpha: 0.15)),
        ),
        child: Icon(Icons.person_rounded, color: fallbackColor, size: 26),
      );
    }

    final bytesAsync = ref.watch(studentPhotoBytesProvider(path));
    return bytesAsync.when(
      data: (bytes) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          border: Border.all(color: AppTheme.darkBorder),
        ),
      ),
      loading: () => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        child: const Center(
          child: SizedBox(
            height: 14, width: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentLime),
          ),
        ),
      ),
      error: (err, stack) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        child: const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
      ),
    );
  }
}
