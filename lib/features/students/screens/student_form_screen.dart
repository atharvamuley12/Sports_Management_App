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
      final image = await _picker.pickImage(source: source, imageQuality: 70);
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
          SnackBar(content: Text('Student ${isEdit ? 'updated' : 'created'} successfully!')),
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
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to permanently delete this student record? This will also remove their attendance and fee payment logs.'),
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
      await ref.read(studentRepositoryProvider).deleteStudent(
            widget.student!.id,
            photoUrl: widget.student!.photoUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student record deleted.')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Student' : 'Add New Student'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo selector

                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Take Photo'),
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
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
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.lime, width: 2),
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
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined, color: Colors.lime, size: 28),
                                          SizedBox(height: 4),
                                          Text('Pick Photo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Student Name *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _parentNameController,
                      decoration: const InputDecoration(labelText: 'Parent/Guardian Name'),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                              return 'Invalid age';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _feeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Monthly Fee (₹) *'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter monthly fee';
                            if (double.tryParse(val) == null) return 'Invalid amount';
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sport Selector
                    DropdownButtonFormField<String>(
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
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Batch Selector
                    batchesAsync.when(
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (err, stack) => Text('Error loading batches: $err'),
                      data: (batches) {
                        // Filter batches for the selected sport
                        final filteredBatches = batches.where((b) => b.sport == _selectedSport).toList();

                        // Reset selected batch if not matching the new filtered list
                        if (_selectedBatchId != null && !filteredBatches.any((b) => b.id == _selectedBatchId)) {
                          _selectedBatchId = null;
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedBatchId,
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
                    const SizedBox(height: 16),

                    // Join Date Selector
                    InkWell(
                      onTap: _selectJoinDate,
                      mouseCursor: SystemMouseCursors.click,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Join Date',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DateFormat('dd MMMM yyyy').format(_selectedJoinDate)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
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
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Save Changes' : 'Create Student'),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Icon(Icons.error, color: Colors.red),
        );
      },
    );
  }
}
