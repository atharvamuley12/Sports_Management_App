import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/attendance.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/models/student.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';
import '../repositories/attendance_repository.dart';

final attendanceBatchesProvider = FutureProvider.autoDispose<List<Batch>>((ref) async {
  final batchRepo = ref.watch(batchRepositoryProvider);
  return await batchRepo.getBatches();
});

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchId;
  List<Student> _students = [];
  Map<String, String> _attendanceMap = {}; // student_id -> 'present' | 'absent'
  List<Attendance> _existingEntries = [];
  bool _isLoading = false;
  bool _isDataLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch initial data once dependencies are ready
    _loadInitialBatch();
  }

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

      // Fetch students and filter for the selected batch
      final allStudents = await studentRepo.getStudents();
      final batchStudents = allStudents.where((s) => s.batchId == _selectedBatchId && s.isActive).toList();

      // Fetch existing attendance logs
      final logs = await attendanceRepo.getAttendanceForBatchAndDate(_selectedBatchId!, _selectedDate);

      final newMap = <String, String>{};
      for (final student in batchStudents) {
        final existing = logs.where((l) => l.studentId == student.id);
        if (existing.isNotEmpty) {
          newMap[student.id] = existing.first.status;
        } else {
          newMap[student.id] = 'present'; // Default
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
      lastDate: DateTime.now(), // Cannot mark future attendance
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
        // Admin uses upsert (can overwrite)
        await attendanceRepo.upsertAttendanceEntries(entries);
      } else {
        // Coach uses insert. If duplicate, DB unique constraint will reject it.
        await attendanceRepo.saveAttendanceEntries(entries);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance recorded successfully!')),
        );
        _loadStudentsAndAttendance(); // Reload
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile!;
    final batchesAsync = ref.watch(attendanceBatchesProvider);

    final alreadyMarked = _existingEntries.isNotEmpty;
    final isReadOnlyForCoach = profile.isCoach && alreadyMarked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Batch and Date panel
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

                      // If selectedBatchId is null or not in current list, select first
                      if (_selectedBatchId == null || !batches.any((b) => b.id == _selectedBatchId)) {
                        Future.microtask(() {
                          setState(() {
                            _selectedBatchId = batches.first.id;
                          });
                          _loadStudentsAndAttendance();
                        });
                      }

                      // If Coach, they only manage their own batch (already filtered by RLS, but list could be length 1)
                      return DropdownButtonFormField<String>(
                        value: _selectedBatchId,
                        decoration: const InputDecoration(labelText: 'Select Batch'),
                        items: batches.map(
                          (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                        ).toList(),
                        onChanged: profile.isCoach
                            ? null // Coach cannot switch batches if they only have one
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

          if (isReadOnlyForCoach)
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
                                  // Attendance toggle
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

          // Action Save button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading || _students.isEmpty || isReadOnlyForCoach ? null : _saveAttendance,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(profile.isAdmin ? 'Save Attendance (Overwrite)' : 'Submit Attendance'),
            ),
          ),
        ],
      ),
    );
  }
}
