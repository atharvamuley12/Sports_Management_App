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
import '../../../shared/widgets/app_widgets.dart';

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
        await batchRepo.createBatch(
          name: _nameController.text.trim(),
          sport: _selectedSport,
          coachId: _selectedCoachId,
          capacity: capVal,
          days: _selectedDays,
          startTime: _startTime,
          endTime: _endTime,
        );

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
          SnackBar(
            content: Text(
              'Batch ${isEdit ? 'updated' : 'created'} successfully!',
              style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard,
          ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Text('Delete Batch', style: AppTheme.heading3),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this batch? All assigned students will be set to unassigned.',
          style: AppTheme.body2.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
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
          SnackBar(
            content: Text(
              'Batch record deleted.',
              style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.darkCard,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sportLower = _selectedSport.toLowerCase();
    Color accentColor = sportLower == 'cricket'
        ? AppTheme.accentLime
        : (sportLower == 'chess' ? AppTheme.accentPurple : AppTheme.accentTeal);
    if (!isDark) {
      if (accentColor == AppTheme.accentLime) {
        accentColor = AppTheme.accentLimeDark;
      } else if (accentColor == AppTheme.accentTeal) {
        accentColor = AppTheme.accentTealDark;
      } else if (accentColor == AppTheme.accentPurple) {
        accentColor = AppTheme.accentPurpleDark;
      }
    }

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
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space12),
              child: AppIconButton(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.errorRed,
                onTap: _isLoading ? null : _delete,
                tooltip: 'Delete Batch',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: accentColor, strokeWidth: 2.5),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: General Details
                    const AppSectionHeader(title: 'BATCH DETAILS', icon: Icons.layers_rounded),
                    const SizedBox(height: AppTheme.space12),

                    TextFormField(
                      controller: _nameController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Batch Name *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: AppTheme.space16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSport,
                            style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                            decoration: const InputDecoration(labelText: 'Sport *'),
                            items: const [
                              DropdownMenuItem(value: 'cricket', child: Text('Cricket')),
                              DropdownMenuItem(value: 'football', child: Text('Football')),
                              DropdownMenuItem(value: 'chess', child: Text('Chess')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSport = val;
                                  _assignedStudentIds.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body1,
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
                    const SizedBox(height: AppTheme.space16),

                    // Coach Selector
                    coachesAsync.when(
                      loading: () => const Center(child: Padding(
                        padding: EdgeInsets.all(AppTheme.space8),
                        child: SizedBox(height: 2, child: LinearProgressIndicator()),
                      )),
                      error: (err, stack) => Text('Error loading coaches: $err', style: AppTheme.caption.copyWith(color: AppTheme.errorRed)),
                      data: (coaches) {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCoachId,
                          style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                    const SizedBox(height: AppTheme.space24),

                    // Days selector
                    const AppSectionHeader(title: 'SCHEDULE DAYS *', icon: Icons.calendar_month_rounded),
                    const SizedBox(height: AppTheme.space12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space8),
                      decoration: AppTheme.subtleCard(borderRadius: AppTheme.radius16, isDark: isDark),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _weekdays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(day.substring(0, 3)),
                            labelStyle: AppTheme.caption.copyWith(
                              color: isSelected ? Colors.black : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius8)),
                            backgroundColor: Colors.transparent,
                            selectedColor: accentColor,
                            checkmarkColor: Colors.black,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),

                    // Timings selector
                    const AppSectionHeader(title: 'TIMINGS', icon: Icons.schedule_rounded),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                              ),
                              child: Text(_startTime ?? 'Select start', style: AppTheme.body1),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            mouseCursor: SystemMouseCursors.click,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                              ),
                              child: Text(_endTime ?? 'Select end', style: AppTheme.body1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space28),

                    // Student selection roster
                    const AppSectionHeader(title: 'ASSIGN STUDENTS', icon: Icons.people_alt_rounded),
                    const SizedBox(height: AppTheme.space12),
                    studentsAsync.when(
                      loading: () => const Center(child: Padding(
                        padding: EdgeInsets.all(AppTheme.space16),
                        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime)),
                      )),
                      error: (err, stack) => Text('Error loading roster: $err', style: AppTheme.caption.copyWith(color: AppTheme.errorRed)),
                      data: (students) {
                        // Filter students by active status and matching sport
                        final sportStudents = students.where((s) => s.isActive && s.sport == _selectedSport).toList();

                        if (sportStudents.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppTheme.space24),
                            child: Center(
                              child: Text(
                                'No active students in this sport.',
                                style: AppTheme.body2.copyWith(color: AppTheme.textMuted),
                              ),
                            ),
                          );
                        }

                        return Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                            child: ListView.separated(
                              itemCount: sportStudents.length,
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
                              separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
                                  title: Text(student.name, style: AppTheme.subtitle2),
                                  subtitle: Text(
                                    '${student.phone ?? 'No Phone'} $assignmentStatus',
                                    style: AppTheme.caption.copyWith(
                                      color: isCurrentBatch ? AppTheme.accentLime : AppTheme.textMuted,
                                    ),
                                  ),
                                  activeColor: accentColor,
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
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.space32),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          isEdit ? 'Save Changes' : 'Create Batch',
                          style: AppTheme.buttonText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
