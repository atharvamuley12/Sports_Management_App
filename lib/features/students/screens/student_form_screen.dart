import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/batch.dart';
import '../../../shared/models/student.dart';
import '../repositories/batch_repository.dart';
import '../repositories/student_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/app_widgets.dart';

final batchesListProvider = FutureProvider.autoDispose<List<Batch>>((ref) async {
  final batchRepo = ref.watch(batchRepositoryProvider);
  return await batchRepo.getBatches();
});

class StudentFormScreen extends ConsumerStatefulWidget {
  final Student? student;

  const StudentFormScreen({super.key, this.student});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _feeController = TextEditingController();

  String _selectedSport = 'cricket';
  String? _selectedBatchId;
  DateTime _selectedJoinDate = DateTime.now();
  String _selectedStatus = 'active';

  XFile? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  bool get isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.student!;
      _nameController.text = s.name;
      _parentNameController.text = s.parentName ?? '';
      _phoneController.text = s.phone ?? '';
      _ageController.text = s.age?.toString() ?? '';
      _feeController.text = s.monthlyFee.toString();
      _selectedSport = s.sport;
      _selectedBatchId = s.batchId;
      _selectedJoinDate = s.joinDate;
      _selectedStatus = s.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() {
          _photoFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to pick image', e);
      }
    }
  }

  Future<void> _selectJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        _selectedJoinDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(studentRepositoryProvider);
      final ageVal = int.tryParse(_ageController.text);
      final feeVal = double.parse(_feeController.text);

      if (isEdit) {
        await repo.updateStudent(
          id: widget.student!.id,
          name: _nameController.text.trim(),
          parentName: _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          age: ageVal,
          sport: _selectedSport,
          batchId: _selectedBatchId,
          monthlyFee: feeVal,
          joinDate: _selectedJoinDate,
          status: _selectedStatus,
          newPhoto: _photoFile,
          existingPhotoUrl: widget.student!.photoUrl,
        );
      } else {
        await repo.createStudent(
          name: _nameController.text.trim(),
          parentName: _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          age: ageVal,
          sport: _selectedSport,
          batchId: _selectedBatchId,
          monthlyFee: feeVal,
          joinDate: _selectedJoinDate,
          status: _selectedStatus,
          photo: _photoFile,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Student ${isEdit ? 'updated' : 'created'} successfully!',
              style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.darkCard,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to save student', e);
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
            Text('Delete Student', style: AppTheme.heading3),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this student record? This will also remove their attendance and fee payment logs.',
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
      await ref.read(studentRepositoryProvider).deleteStudent(
            widget.student!.id,
            photoUrl: widget.student!.photoUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Student record deleted.',
              style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.darkCard,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to delete student', e);
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
    final batchesAsync = ref.watch(batchesListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Student' : 'Add New Student'),
        actions: [
          if (isEdit)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space12),
              child: AppIconButton(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.errorRed,
                onTap: _isLoading ? null : _delete,
                tooltip: 'Delete Student',
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
                    // Photo selector
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (ctx) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_rounded),
                                        title: const Text('Take Photo'),
                                        onTap: () {
                                          Navigator.of(ctx).pop();
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_rounded),
                                        title: const Text('Choose from Gallery'),
                                        onTap: () {
                                          Navigator.of(ctx).pop();
                                          _pickImage(ImageSource.gallery);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: _photoFile != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_photoFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : widget.student?.photoUrl != null
                                      ? ClipOval(
                                          child: _buildSavedPhoto(widget.student!.photoUrl!),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_outlined, color: accentColor, size: 28),
                                            const SizedBox(height: AppTheme.space4),
                                            Text(
                                              'Pick Photo',
                                              style: AppTheme.caption.copyWith(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                          if (_photoFile != null || widget.student?.photoUrl != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.space6),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.outline, width: 0.6),
                                ),
                                child: Icon(Icons.edit_rounded, size: 14, color: accentColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space32),

                    // Section: General Details
                    const AppSectionHeader(title: 'GENERAL DETAILS', icon: Icons.person_outline_rounded),
                    const SizedBox(height: AppTheme.space12),

                    TextFormField(
                      controller: _nameController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Student Name *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: AppTheme.space16),

                    TextFormField(
                      controller: _parentNameController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Parent/Guardian Name'),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Age'),
                            validator: (val) {
                              if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                                return 'Invalid age';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: TextFormField(
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Fee (₹) *',
                              prefixIcon: Icon(Icons.currency_rupee, size: 16),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter monthly fee';
                              if (double.tryParse(val) == null) return 'Invalid amount';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space32),

                    // Section: Academy Configuration
                    const AppSectionHeader(title: 'ACADEMY CONFIGURATION', icon: Icons.sports_outlined),
                    const SizedBox(height: AppTheme.space12),

                    // Sport Selector
                    DropdownButtonFormField<String>(
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
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Batch Selector
                    batchesAsync.when(
                      loading: () => const Center(child: Padding(
                        padding: EdgeInsets.all(AppTheme.space16),
                        child: SizedBox(height: 2, child: LinearProgressIndicator()),
                      )),
                      error: (err, stack) => Text('Error loading batches: $err', style: AppTheme.caption.copyWith(color: AppTheme.errorRed)),
                      data: (batches) {
                        // Filter batches for the selected sport
                        final filteredBatches = batches.where((b) => b.sport == _selectedSport).toList();

                        // Reset selected batch if not matching the new filtered list
                        if (_selectedBatchId != null && !filteredBatches.any((b) => b.id == _selectedBatchId)) {
                          _selectedBatchId = null;
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedBatchId,
                          style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: const InputDecoration(labelText: 'Assigned Batch'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('No Batch')),
                            ...filteredBatches.map(
                              (b) => DropdownMenuItem<String>(value: b.id, child: Text(b.name)),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Join Date Selector
                    InkWell(
                      onTap: _selectJoinDate,
                      mouseCursor: SystemMouseCursors.click,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Join Date',
                          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          DateFormat('dd MMMM yyyy').format(_selectedJoinDate),
                          style: AppTheme.body1,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      style: AppTheme.body1.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.space40),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          isEdit ? 'Save Changes' : 'Create Student',
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

  Widget _buildSavedPhoto(String path) {
    return Consumer(
      builder: (context, ref, child) {
        final bytesAsync = ref.watch(studentPhotoBytesProvider(path));
        return bytesAsync.when(
          data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
          loading: () => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
            ),
          ),
          error: (err, stack) => const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
        );
      },
    );
  }
}
