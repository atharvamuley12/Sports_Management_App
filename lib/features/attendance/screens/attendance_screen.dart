import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';
import '../repositories/attendance_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_utils.dart';

final attendanceBatchesProvider = FutureProvider.autoDispose<List<Batch>>((ref) async {
  final batchRepo = ref.watch(batchRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  final profile = authState.profile;
  final allBatches = await batchRepo.getBatches();
  if (profile != null && profile.isCoach) {
    return allBatches.where((b) => b.coachId == profile.id).toList();
  }
  return allBatches;
});

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 (Log Attendance) State
  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchId;
  List<Student> _students = [];
  Map<String, String> _attendanceMap = {}; // student_id -> 'present' | 'absent'
  List<Attendance> _existingEntries = [];
  bool _isLoading = false;
  bool _isDataLoading = false;

  // Tab 2 (History Log) State
  DateTime? _historyDate;
  String? _historyBatchId;
  String _historySearchQuery = '';
  List<Map<String, dynamic>> _historyLogs = [];
  bool _isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadHistoryLogs();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialBatch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── TAB 1: LOG ATTENDANCE METHODS ──────────────────────────────

  Future<void> _loadInitialBatch() async {
    final batchesList = ref.read(attendanceBatchesProvider).value ?? [];
    if (batchesList.isNotEmpty && _selectedBatchId == null) {
      setState(() {
        _selectedBatchId = batchesList.first.id;
      });
      _loadStudentsAndAttendance();
    }
  }

  Future<void> _loadStudentsAndAttendance() async {
    if (_selectedBatchId == null) return;

    setState(() {
      _isDataLoading = true;
    });

    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final attendanceRepo = ref.read(attendanceRepositoryProvider);

      final allStudents = await studentRepo.getStudents();
      final batchStudents = allStudents.where((s) => s.batchId == _selectedBatchId && s.isActive).toList();

      final logs = await attendanceRepo.getAttendanceForBatchAndDate(_selectedBatchId!, _selectedDate);

      final newMap = <String, String>{};
      for (final student in batchStudents) {
        final existing = logs.where((l) => l.studentId == student.id);
        if (existing.isNotEmpty) {
          newMap[student.id] = existing.first.status;
        } else {
          newMap[student.id] = 'present';
        }
      }

      setState(() {
        _students = batchStudents;
        _existingEntries = logs;
        _attendanceMap = newMap;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.accentLime,
                    onPrimary: Colors.black,
                    surface: AppTheme.darkCard,
                    onSurface: AppTheme.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.accentLimeDark,
                    onPrimary: Colors.white,
                    surface: AppTheme.lightCard,
                    onSurface: AppTheme.textPrimaryLight,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadStudentsAndAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedBatchId == null || _students.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceRepo = ref.read(attendanceRepositoryProvider);
      final profile = ref.read(authControllerProvider).profile!;

      final entries = _students.map((student) {
        return {
          'student_id': student.id,
          'date': "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
          'status': _attendanceMap[student.id] ?? 'present',
          'marked_by': profile.id,
        };
      }).toList();

      if (profile.isAdmin) {
        await attendanceRepo.upsertAttendanceEntries(entries);
      } else {
        await attendanceRepo.saveAttendanceEntries(entries);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance recorded successfully!',
              style: AppTheme.body2.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.textPrimary
                    : AppTheme.textPrimaryLight,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard,
          ),
        );
        _loadStudentsAndAttendance();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('unique') || msg.contains('duplicate')) {
          msg = 'Attendance has already been marked for this date.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $msg'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── TAB 2: HISTORY LOG METHODS ────────────────────────────────

  Future<void> _loadHistoryLogs() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      
      var query = supabase
          .from('attendance')
          .select('id, date, status, marked_by, students!inner(name, batch_id)');

      final profile = ref.read(authControllerProvider).profile!;
      if (profile.isCoach) {
        final coachBatches = ref.read(attendanceBatchesProvider).value ?? [];
        final coachBatchIds = coachBatches.map((b) => b.id).toList();
        if (_historyBatchId != null) {
          query = query.eq('students.batch_id', _historyBatchId!);
        } else if (coachBatchIds.isNotEmpty) {
          query = query.inFilter('students.batch_id', coachBatchIds);
        } else {
          setState(() {
            _historyLogs = [];
            _isHistoryLoading = false;
          });
          return;
        }
      } else {
        if (_historyBatchId != null) {
          query = query.eq('students.batch_id', _historyBatchId!);
        }
      }
      if (_historyDate != null) {
        final dateStr = "${_historyDate!.year.toString().padLeft(4, '0')}-${_historyDate!.month.toString().padLeft(2, '0')}-${_historyDate!.day.toString().padLeft(2, '0')}";
        query = query.eq('date', dateStr);
      }
      if (_historySearchQuery.isNotEmpty) {
        query = query.ilike('students.name', '%$_historySearchQuery%');
      }

      final response = await query.order('date', ascending: false);
      setState(() {
        _historyLogs = (response as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _toggleHistoryStatus(Map<String, dynamic> log) async {
    final newStatus = log['status'] == 'present' ? 'absent' : 'present';
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.updateAttendanceEntry(id: log['id'], status: newStatus);
      
      setState(() {
        log['status'] = newStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated successfully!',
              style: AppTheme.body2.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.textPrimary
                    : AppTheme.textPrimaryLight,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to update attendance status', e);
      }
    }
  }

  // ─── BUILDERS ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;
    final batchesAsync = ref.watch(attendanceBatchesProvider);

    final alreadyMarked = _existingEntries.isNotEmpty;
    final isRestrictedCoach = profile.isCoach && !profile.isActive;
    final isReadOnlyForCoach = (profile.isCoach && alreadyMarked) || isRestrictedCoach;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Mark Attendance'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'History Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkAttendanceTab(batchesAsync, profile, isReadOnlyForCoach, isRestrictedCoach, alreadyMarked),
          _buildHistoryLogTab(batchesAsync, profile),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceTab(
    AsyncValue<List<Batch>> batchesAsync,
    Profile profile,
    bool isReadOnlyForCoach,
    bool isRestrictedCoach,
    bool alreadyMarked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: AppCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        mouseCursor: SystemMouseCursors.click,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Attendance Date',
                            suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy').format(_selectedDate),
                            style: AppTheme.body1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                batchesAsync.when(
                  loading: () => const Center(child: SizedBox(height: 2, child: LinearProgressIndicator())),
                  error: (err, stack) => Text('Error loading batches: $err', style: AppTheme.caption.copyWith(color: AppTheme.errorRed)),
                  data: (batches) {
                    if (batches.isEmpty) {
                      return Text('No batches found.', style: AppTheme.caption.copyWith(color: AppTheme.textMuted));
                    }

                    if (_selectedBatchId == null || !batches.any((b) => b.id == _selectedBatchId)) {
                      Future.microtask(() {
                        setState(() {
                          _selectedBatchId = batches.first.id;
                        });
                        _loadStudentsAndAttendance();
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedBatchId,
                      style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: const InputDecoration(labelText: 'Select Batch'),
                      items: batches.map(
                        (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                      ).toList(),
                      onChanged: (val) {
                              setState(() {
                                _selectedBatchId = val;
                              });
                              _loadStudentsAndAttendance();
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        if (isRestrictedCoach)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.06),
              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppTheme.errorRed, size: 20),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'Your account is Restricted. Attendance modifications have been disabled.',
                    style: AppTheme.caption.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        else if (isReadOnlyForCoach)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withValues(alpha: 0.06),
              border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppTheme.warningAmber, size: 20),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'Attendance already marked for today. Only administrators can edit/correct attendance.',
                    style: AppTheme.caption.copyWith(color: AppTheme.warningAmber),
                  ),
                ),
              ],
            ),
          ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
          child: AppSectionHeader(
            title: 'STUDENTS ROSTER',
            icon: Icons.people_alt_rounded,
          ),
        ),

        Expanded(
          child: _isDataLoading
              ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
              : _students.isEmpty
                  ? Center(
                      child: Text(
                        'No active students in this batch.',
                        style: AppTheme.body2.copyWith(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _students.length,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final currentStatus = _attendanceMap[student.id] ?? 'present';
                        final isPresent = currentStatus == 'present';
                        final statusColor = isPresent ? AppTheme.successGreen : AppTheme.errorRed;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space8),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppTheme.space10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Icon(
                                    isPresent ? Icons.check_rounded : Icons.close_rounded,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: AppTheme.subtitle2,
                                      ),
                                      if (student.phone != null && student.phone!.isNotEmpty) ...[
                                        const SizedBox(height: AppTheme.space2),
                                        Text(
                                          student.phone!,
                                          style: AppTheme.caption,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                  Switch(
                                    value: isPresent,
                                    activeThumbColor: AppTheme.accentLime,
                                  onChanged: isReadOnlyForCoach
                                      ? null
                                      : (val) {
                                          setState(() {
                                            _attendanceMap[student.id] = val ? 'present' : 'absent';
                                          });
                                        },
                                ),
                                const SizedBox(width: AppTheme.space8),
                                isPresent ? AppStatusChip.present() : AppStatusChip.absent(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading || _students.isEmpty || isReadOnlyForCoach ? null : _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLime,
                foregroundColor: Colors.black,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      isRestrictedCoach
                          ? 'Submit (Restricted)'
                          : (profile.isAdmin ? 'Save Attendance (Overwrite)' : 'Submit Attendance'),
                      style: AppTheme.buttonText,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogTab(AsyncValue<List<Batch>> batchesAsync, Profile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: AppCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _historyDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: isDark
                                      ? const ColorScheme.dark(
                                          primary: AppTheme.accentLime,
                                          onPrimary: Colors.black,
                                          surface: AppTheme.darkCard,
                                          onSurface: AppTheme.textPrimary,
                                        )
                                      : const ColorScheme.light(
                                          primary: AppTheme.accentLimeDark,
                                          onPrimary: Colors.white,
                                          surface: AppTheme.lightCard,
                                          onSurface: AppTheme.textPrimaryLight,
                                        ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          setState(() {
                            _historyDate = picked;
                          });
                          _loadHistoryLogs();
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Filter Date',
                            suffixIcon: _historyDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _historyDate = null;
                                      });
                                      _loadHistoryLogs();
                                    },
                                  )
                                : const Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                          child: Text(
                            _historyDate != null ? DateFormat('dd MMM yyyy').format(_historyDate!) : 'All Dates',
                            style: AppTheme.body1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                batchesAsync.when(
                  loading: () => const Center(child: SizedBox(height: 2, child: LinearProgressIndicator())),
                  error: (err, stack) => const SizedBox(),
                  data: (batches) {
                     return DropdownButtonFormField<String>(
                      initialValue: _historyBatchId,
                      style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: const InputDecoration(labelText: 'Filter Batch'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Batches')),
                        ...batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                      ],
                      onChanged: (val) {
                              setState(() {
                                _historyBatchId = val;
                              });
                              _loadHistoryLogs();
                            },
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),
                AppSearchBar(
                  hint: 'Search student name...',
                  onChanged: (val) {
                    setState(() {
                      _historySearchQuery = val.trim();
                    });
                    _loadHistoryLogs();
                  },
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _isHistoryLoading
              ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.accentLime)))
              : _historyLogs.isEmpty
                  ? Center(
                      child: Text(
                        'No historical logs match your filters.',
                        style: AppTheme.body2.copyWith(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _historyLogs.length,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                      itemBuilder: (context, idx) {
                        final log = _historyLogs[idx];
                        final studentName = (log['students'] as Map<String, dynamic>)['name'] as String;
                         final dateStr = DateFormat('dd MMM yyyy').format(DateUtilsHelper.parseSqlDate(log['date'] as String));
                         final isPresent = log['status'] == 'present';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space8),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(studentName, style: AppTheme.subtitle1),
                                      const SizedBox(height: AppTheme.space4),
                                      Row(
                                        children: [
                                          Icon(Icons.event_rounded, size: 12, color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
                                          const SizedBox(width: AppTheme.space4),
                                          Text(
                                            'Date: $dateStr',
                                            style: AppTheme.caption.copyWith(
                                              color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    isPresent ? AppStatusChip.present() : AppStatusChip.absent(),
                                    if (profile.isAdmin) ...[
                                      const SizedBox(width: AppTheme.space8),
                                      AppIconButton(
                                        icon: Icons.swap_horiz_rounded,
                                        color: AppTheme.accentLime,
                                        onTap: () => _toggleHistoryStatus(log),
                                        tooltip: 'Toggle present/absent',
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
