import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';
import '../repositories/attendance_repository.dart';
import '../../../core/utils/error_handler.dart';

final attendanceBatchesProvider = FutureProvider.autoDispose<List<Batch>>((ref) async {
  final batchRepo = ref.watch(batchRepositoryProvider);
  return await batchRepo.getBatches();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
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
          const SnackBar(content: Text('Attendance recorded successfully!')),
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
          SnackBar(content: Text('Save failed: $msg')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ─── TAB 2: HISTORY LOG METHODS ────────────────────────────────

  Future<void> _loadHistoryLogs() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // Perform inner join select to filter by batch and name
      var query = supabase
          .from('attendance')
          .select('id, date, status, marked_by, students!inner(name, batch_id)');

      if (_historyBatchId != null) {
        query = query.eq('students.batch_id', _historyBatchId!);
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
          SnackBar(content: Text('Failed to load history: $e')),
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
      
      // Update local state
      setState(() {
        log['status'] = newStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully!')),
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
          indicatorColor: AppTheme.accentLime,
          labelColor: AppTheme.accentLime,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Mark Attendance'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Mark Attendance
          _buildMarkAttendanceTab(batchesAsync, profile, isReadOnlyForCoach, isRestrictedCoach, alreadyMarked),
          
          // TAB 2: History Log
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
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                batchesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => Text('Error batches: $err'),
                  data: (batches) {
                    if (batches.isEmpty) {
                      return const Text('No batches found. Check database.');
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
                      value: _selectedBatchId,
                      decoration: const InputDecoration(labelText: 'Select Batch'),
                      items: batches.map(
                        (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                      ).toList(),
                      onChanged: profile.isCoach
                          ? null
                          : (val) {
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
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.08),
              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppTheme.errorRed),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your account is Restricted. Attendance modifications have been disabled.',
                    style: TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        else if (isReadOnlyForCoach)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withValues(alpha: 0.08),
              border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppTheme.warningAmber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance already marked for today. Only administrators can edit/correct attendance.',
                    style: TextStyle(color: AppTheme.warningAmber, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Students Roster',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: _isDataLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? const Center(child: Text('No active students in this batch.'))
                  : ListView.builder(
                      itemCount: _students.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final currentStatus = _attendanceMap[student.id] ?? 'present';
                        final isPresent = currentStatus == 'present';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isPresent ? AppTheme.successGreen.withValues(alpha: 0.15) : AppTheme.errorRed.withValues(alpha: 0.15),
                                  child: Icon(
                                    isPresent ? Icons.check_rounded : Icons.close_rounded,
                                    color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        student.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      if (student.phone != null)
                                        SelectableText(
                                          student.phone!,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isPresent,
                                  activeColor: AppTheme.accentLime,
                                  onChanged: isReadOnlyForCoach
                                      ? null
                                      : (val) {
                                          setState(() {
                                            _attendanceMap[student.id] = val ? 'present' : 'absent';
                                          });
                                        },
                                ),
                                Text(
                                  isPresent ? 'PRESENT' : 'ABSENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading || _students.isEmpty || isReadOnlyForCoach ? null : _saveAttendance,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isRestrictedCoach
                    ? 'Submit (Restricted)'
                    : (profile.isAdmin ? 'Save Attendance (Overwrite)' : 'Submit Attendance')),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogTab(AsyncValue<List<Batch>> batchesAsync, Profile profile) {
    return Column(
      children: [
        // History filters panel
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _historyDate = null;
                                      });
                                      _loadHistoryLogs();
                                    },
                                  )
                                : const Icon(Icons.calendar_today),
                          ),
                          child: Text(_historyDate != null ? DateFormat('dd MMM yyyy').format(_historyDate!) : 'All Dates'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                batchesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => const SizedBox(),
                  data: (batches) {
                    return DropdownButtonFormField<String>(
                      value: _historyBatchId,
                      decoration: const InputDecoration(labelText: 'Filter Batch'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Batches')),
                        ...batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                      ],
                      onChanged: profile.isCoach
                          ? null
                          : (val) {
                              setState(() {
                                _historyBatchId = val;
                              });
                              _loadHistoryLogs();
                            },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search student name...',
                    prefixIcon: Icon(Icons.search),
                  ),
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

        // History logs list
        Expanded(
          child: _isHistoryLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentLime))
              : _historyLogs.isEmpty
                  ? const Center(child: Text('No historical logs match your filters.'))
                  : ListView.builder(
                      itemCount: _historyLogs.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, idx) {
                        final log = _historyLogs[idx];
                        final studentName = (log['students'] as Map<String, dynamic>)['name'] as String;
                        final dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(log['date'] as String));
                        final isPresent = log['status'] == 'present';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: SelectableText(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Date: $dateStr', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isPresent ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    log['status'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                                if (profile.isAdmin) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.accentLime),
                                    onPressed: () => _toggleHistoryStatus(log),
                                    tooltip: 'Toggle present/absent',
                                  ),
                                ],
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
