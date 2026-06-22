import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/profile.dart';
import '../../auth/repositories/profile_repository.dart';
import '../../../core/utils/error_handler.dart';

final coachesListProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return await profileRepo.getCoaches();
});

class CoachesScreen extends ConsumerStatefulWidget {
  const CoachesScreen({super.key});

  @override
  ConsumerState<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends ConsumerState<CoachesScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(coachesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Accounts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCoachDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(coachesListProvider);
        },
        child: coachesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading coaches: $err'),
            ),
          ),
          data: (coaches) {
            if (coaches.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No coaches added yet.')),
                ],
              );
            }

            return ListView.builder(
              itemCount: coaches.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final coach = coaches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.accentLime.withValues(alpha: 0.15),
                          child: const Icon(Icons.sports_rounded, color: AppTheme.accentLime),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                coach.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              if (coach.phone != null)
                                SelectableText(
                                  coach.phone!,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              Text(
                                coach.isActive ? 'Active Staff' : 'Deactivated',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: coach.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Active switch
                        Switch(
                          value: coach.isActive,
                          activeColor: AppTheme.accentLime,
                          onChanged: (val) async {
                            try {
                              final repo = ref.read(profileRepositoryProvider);
                              await repo.toggleCoachActive(coach.id, val);
                              ref.invalidate(coachesListProvider);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Coach status updated!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ErrorHandler.showError(context, 'Failed to update', e);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddCoachDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final formKey = GlobalKey<FormState>();
          final nameController = TextEditingController();
          final emailController = TextEditingController();
          final phoneController = TextEditingController();
          final passwordController = TextEditingController();

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(profileRepositoryProvider);

              await repo.createCoachUser(
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text,
              );

              ref.invalidate(coachesListProvider);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coach user created successfully!')),
                );
              }
            } catch (e) {
              if (mounted) {
                ErrorHandler.showError(context, 'Failed to create coach', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Add Coach Account'),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Full Name *'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email Address *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter email';
                              if (!val.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Temporary Password *',
                              hintText: 'Must be at least 6 characters',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter password';
                              if (val.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : submit,
                child: const Text('Create Coach'),
              ),
            ],
          );
        },
      ),
    );
  }
}
