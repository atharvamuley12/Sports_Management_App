import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/widgets/app_widgets.dart';
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
        child: const Icon(Icons.add_rounded, size: 24),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        onRefresh: () async {
          ref.invalidate(coachesListProvider);
        },
        child: coachesAsync.when(
          loading: () => const AppLoadingState(itemCount: 4, itemHeight: 90),
          error: (err, stack) => AppErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(coachesListProvider),
          ),
          data: (coaches) {
            if (coaches.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.supervised_user_circle_rounded,
                    title: 'No coaches added yet',
                    subtitle: 'Use the floating action button below to create a new coach account.',
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: coaches.length,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.space16),
              itemBuilder: (context, index) {
                final coach = coaches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space12),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radius12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                          ),
                          child: Icon(Icons.sports_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: AppTheme.space14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coach.fullName,
                                style: AppTheme.subtitle1,
                              ),
                              if (coach.phone != null && coach.phone!.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.space2),
                                Text(
                                  coach.phone!,
                                  style: AppTheme.caption,
                                ),
                              ],
                              const SizedBox(height: AppTheme.space4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: (coach.isActive ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    coach.isActive ? 'Active Staff' : 'Suspended',
                                    style: AppTheme.overline.copyWith(
                                      fontSize: 9,
                                      color: coach.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Actions Group (Switch + PopupMenuButton)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: coach.isActive,
                              activeThumbColor: Theme.of(context).colorScheme.primary,
                              onChanged: (val) async {
                                try {
                                  final repo = ref.read(profileRepositoryProvider);
                                  await repo.toggleCoachActive(coach.id, val);
                                  ref.invalidate(coachesListProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Coach status updated!',
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
                                  if (context.mounted) {
                                    ErrorHandler.showError(context, 'Failed to update', e);
                                  }
                                }
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                              ),
                              surfaceTintColor: Colors.transparent,
                              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditCoachDialog(coach);
                                } else if (val == 'reset') {
                                  _showResetPasswordDialog(coach);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reset',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_reset_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('Reset Password'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  void _showEditCoachDialog(Profile coach) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: coach.fullName);
    final phoneController = TextEditingController(text: coach.phone ?? '');
    final emailController = TextEditingController(text: coach.email ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(profileRepositoryProvider);
              await repo.updateCoachProfile(
                coachId: coach.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? '' : phoneController.text.trim(),
                email: emailController.text.trim(),
              );

              ref.invalidate(coachesListProvider);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coach profile updated successfully!',
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
                ErrorHandler.showError(context, 'Failed to update coach profile', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius10),
                  ),
                  child: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Text('Edit Details', style: AppTheme.heading3),
              ],
            ),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                      ),
                    ),
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
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Full Name *'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Email Address *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter email';
                              if (!val.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Phone Number'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                ),
                child: const Text('Save Details'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPasswordDialog(Profile coach) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(profileRepositoryProvider);
              await repo.resetCoachPassword(coach.id, passwordController.text);

              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset successfully for ${coach.fullName}!',
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
                ErrorHandler.showError(context, 'Failed to reset password', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius10),
                  ),
                  child: Icon(Icons.lock_reset_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    'Reset Password',
                    style: AppTheme.heading3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                      ),
                    ),
                  )
                : Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: AppTheme.body1,
                          decoration: const InputDecoration(
                            labelText: 'New Password *',
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
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                ),
                child: const Text('Reset Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCoachDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {

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
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coach user created successfully!',
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
                ErrorHandler.showError(context, 'Failed to create coach', e);
              }
            } finally {
              setState(() {
                _isSaving = false;
              });
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius10),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: AppTheme.space12),
                Text('Add Coach Account', style: AppTheme.heading3),
              ],
            ),
            content: _isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentLime),
                      ),
                    ),
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
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Full Name *'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Email Address *'),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter email';
                              if (!val.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            style: AppTheme.body1,
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: AppTheme.body1,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                ),
                child: const Text('Create Coach'),
              ),
            ],
          );
        },
      ),
    );
  }
}
