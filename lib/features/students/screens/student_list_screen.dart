import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/student.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/student_repository.dart';

final studentListProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  final studentRepo = ref.watch(studentRepositoryProvider);
  return await studentRepo.getStudents();
});

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;
    final studentListAsync = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          if (profile.isAdmin || profile.isCoach)
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    return matchesName || matchesPhone;
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
                                _searchQuery.isEmpty ? 'No students yet' : 'No students found',
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
                      return _buildStudentCard(context, ref, student, profile.isAdmin);
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

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, Student student, bool isAdmin) {
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
            await context.push('/students/edit', extra: student);
            ref.invalidate(studentListProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Photo
                _buildStudentPhoto(ref, student.photoUrl, sportColor),
                const SizedBox(width: 14),
                // Info
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
                // Status badge + chevron
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
