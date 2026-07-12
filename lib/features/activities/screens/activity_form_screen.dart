import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../controllers/activity_controller.dart';
import '../../../shared/models/activity.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  final Activity? activity;
  final DateTime? initialDate;

  const ActivityFormScreen({super.key, this.activity, this.initialDate});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity?.title ?? '');
    _descriptionController = TextEditingController(text: widget.activity?.description ?? '');
    _selectedDate = widget.activity?.date ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final success = widget.activity == null
        ? await ref.read(activityControllerProvider.notifier).addActivity(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              date: _selectedDate,
            )
        : await ref.read(activityControllerProvider.notifier).updateActivity(
              widget.activity!.copyWith(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                date: _selectedDate,
              ),
            );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(activityControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? 'New Activity' : 'Edit Activity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: AppTheme.inputDecoration(isDark: Theme.of(context).brightness == Brightness.dark),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: AppTheme.accentGold),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: AppTheme.caption.copyWith(color: AppTheme.textMuted)),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                              style: AppTheme.subtitle1,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Morning Batting Practice',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: AppTheme.space20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the drills, focus areas, or goals...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: AppTheme.space32),
              ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
