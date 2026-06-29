import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/student.dart';
import '../../auth/repositories/profile_repository.dart';
import '../../students/repositories/batch_repository.dart';
import '../../students/repositories/student_repository.dart';
import '../../../core/utils/error_handler.dart';

final formCoachesProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getCoaches();
});

final formStudentsProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return await repo.getStudents();
});

class BatchFormScreen extends ConsumerStatefulWidget {
  final Batch? batch;

  const BatchFormScreen({super.key, this.batch});

  @override
  ConsumerState<BatchFormScreen> createState() => _BatchFormScreenState();
}

class _BatchFormScreenState extends ConsumerState<BatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '20');

  String _selectedSport = 'cricket';
  String? _selectedCoachId;
  List<String> _selectedDays = [];
  String? _startTime;
  String? _endTime;
  
  // Track selected students for this batch
  List<String> _assignedStudentIds = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;

  bool get isEdit => widget.batch != null;

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final b = widget.batch!;
      _nameController.text = b.name;
      _capacityController.text = b.capacity.toString();
      _selectedSport = b.sport;
      _selectedCoachId = b.coachId;
      _selectedDays = List.from(b.days);
      _startTime = b.startTime;
      _endTime = b.endTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          final formatted = picked.format(context);
          if (isStart) {
            _startTime = formatted;
          } else {
            _endTime = formatted;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batchRepo = ref.read(batchRepositoryProvider);
      final capVal = int.parse(_capacityController.text);

      String? batchId = widget.batch?.id;

      if (isEdit) {
        await batchRepo.updateBatch(
          id: batchId!,
          name: _nameController.text.trim(),
          sport: _selectedSport,
          coachId: _selectedCoachId,
          capacity: capVal,
          days: _selectedDays,
          startTime: _startTime,
          endTime: _endTime,
        );
      } else {
        // Create batch and get list update, since we need the ID we will insert and fetch
        // Or wait, supabase insert doesn't directly return it here unless we do select()
        // Let's perform standard insert. In Supabase we can select the inserted batch by name/time or use custom flow.
        // Actually, we can fetch all batches after creation to find the newly created one,
        // or just insert.
        // Let's insert the batch
        await batchRepo.createBatch(
          name: _nameController.text.trim(),
          sport: _selectedSport,
          coachId: _selectedCoachId,
          capacity: capVal,
          days: _selectedDays,
          startTime: _startTime,
          endTime: _endTime,
        );

        // Fetch batches to find the ID of the one we just created (matching name)
        final batchesList = await batchRepo.getBatches();
        final match = batchesList.where((b) => b.name == _nameController.text.trim()).toList();
        if (match.isNotEmpty) {
          batchId = match.first.id;
        }
      }

      // Assign selected students to the batch
      if (batchId != null) {
        await batchRepo.updateBatchStudents(batchId, _assignedStudentIds);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch ${isEdit ? 'updated' : 'created'} successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to save batch', e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Batch'),
        content: const Text('Are you sure you want to permanently delete this batch? All assigned students will be set to unassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batchRepo = ref.read(batchRepositoryProvider);
      
      // Clear students
      await batchRepo.updateBatchStudents(widget.batch!.id, []);
      
      // Delete batch
      await batchRepo.deleteBatch(widget.batch!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch record deleted.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to delete batch', e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(formCoachesProvider);
    final studentsAsync = ref.watch(formStudentsProvider);

    // Initial student selection mapping
    if (isEdit && _isFirstLoad && studentsAsync.hasValue) {
      final allStudents = studentsAsync.value!;
      final batchStudents = allStudents.where((s) => s.batchId == widget.batch!.id).map((s) => s.id).toList();
      _assignedStudentIds = batchStudents;
      _isFirstLoad = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Batch' : 'Create Batch'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentLime))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Batch Name *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSport,
                            decoration: const InputDecoration(labelText: 'Sport *'),
                            items: const [
                              DropdownMenuItem(value: 'cricket', child: Text('Cricket')),
                              DropdownMenuItem(value: 'football', child: Text('Football')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSport = val;
                                  // Clear student selection when sport changes
                                  _assignedStudentIds.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Capacity *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter capacity';
                              if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Invalid capacity';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Coach Selector
                    coachesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => Text('Error loading coaches: $err'),
                      data: (coaches) {
                        return DropdownButtonFormField<String>(
                          value: _selectedCoachId,
                          decoration: const InputDecoration(labelText: 'Assigned Coach'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                            ...coaches.map(
                              (c) => DropdownMenuItem<String>(value: c.id, child: Text(c.fullName)),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCoachId = val;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Days selector
                    const Text('Schedule Days *', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Wrap(
                        spacing: 8,
                        children: _weekdays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(day.substring(0, 3)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                            selectedColor: _selectedSport == 'cricket' ? AppTheme.accentLime.withValues(alpha: 0.3) : AppTheme.accentTeal.withValues(alpha: 0.3),
                            checkmarkColor: _selectedSport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timings selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_startTime ?? 'Select start'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_endTime ?? 'Select end'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Student selection roster
                    const Text('Assign Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    studentsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error loading roster: $err'),
                      data: (students) {
                        // Filter students by active status and matching sport
                        final sportStudents = students.where((s) => s.isActive && s.sport == _selectedSport).toList();

                        if (sportStudents.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: Text('No active students in this sport.', style: TextStyle(color: AppTheme.textMuted))),
                          );
                        }

                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: ListView.builder(
                            itemCount: sportStudents.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, idx) {
                              final student = sportStudents[idx];
                              final isCurrentBatch = student.batchId == widget.batch?.id;
                              final isSelected = _assignedStudentIds.contains(student.id);

                              // Text formatting
                              String assignmentStatus = '';
                              if (isCurrentBatch) {
                                assignmentStatus = '(Current)';
                              } else if (student.batchId != null) {
                                assignmentStatus = '(In another batch)';
                              }

                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(
                                  '${student.phone ?? 'No Phone'} $assignmentStatus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isCurrentBatch ? AppTheme.accentLime : AppTheme.textMuted,
                                  ),
                                ),
                                activeColor: _selectedSport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal,
                                checkColor: Colors.black,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _assignedStudentIds.add(student.id);
                                    } else {
                                      _assignedStudentIds.remove(student.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Save Changes' : 'Create Batch'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
