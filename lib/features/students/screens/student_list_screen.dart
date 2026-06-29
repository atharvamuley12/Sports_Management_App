import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/batch.dart';
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
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.limeGradient,
                borderRadius: BorderRadius.circular(12),
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
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppTheme.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          
          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
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
              onRefresh: () async {
                ref.invalidate(studentListProvider);
              },
              child: studentListAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentLime, strokeWidth: 2.5),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorRed),
                        const SizedBox(height: 12),
                        SelectableText(
                          'Error loading students: $err',
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
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
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline_rounded, size: 56, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty ? 'No students matches' : 'No students found',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.darkCard,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary, size: 20),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, Student student) {
    final sportColor = student.sport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            await context.push('/students/profile', extra: student);
            ref.invalidate(studentListProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildStudentPhoto(ref, student.photoUrl, sportColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (student.age != null)
                            _infoPill('Age ${student.age}', AppTheme.textMuted),
                          if (student.age != null) const SizedBox(width: 6),
                          _infoPill(
                            student.sport.toUpperCase(),
                            sportColor,
                            isBold: true,
                          ),
                        ],
                      ),
                      if (student.phone != null) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          student.phone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (student.isActive ? AppTheme.successGreen : AppTheme.errorRed)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (student.isActive ? AppTheme.successGreen : AppTheme.errorRed)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        student.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: student.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoPill(String text, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color,
          letterSpacing: isBold ? 0.5 : 0,
        ),
      ),
    );
  }

  Widget _buildStudentPhoto(WidgetRef ref, String? path, Color fallbackColor) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fallbackColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.person_rounded, color: fallbackColor, size: 24),
      );
    }

    final bytesAsync = ref.watch(studentPhotoBytesProvider(path));
    return bytesAsync.when(
      data: (bytes) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
        ),
      ),
      loading: () => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            height: 16, width: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentLime),
          ),
        ),
      ),
      error: (err, stack) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
      ),
    );
  }
}

