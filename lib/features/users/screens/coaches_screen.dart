import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/repositories/profile_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/supabase/supabase_client.dart';

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space12,
                    ),
                    child: Row(
                      children: [
                        _buildCoachPhoto(ref, coach.photoUrl, context),
                        const SizedBox(width: AppTheme.space14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coach.fullName,
                                style: AppTheme.subtitle1,
                              ),
                              const SizedBox(height: AppTheme.space4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (coach.speciality != null && coach.speciality!.isNotEmpty)
                                    _infoPill(coach.speciality!, Theme.of(context).colorScheme.primary),
                                  if (coach.experience != null && coach.experience!.isNotEmpty)
                                    _infoPill('${coach.experience} Exp', AppTheme.textMuted),
                                ],
                              ),
                              if (coach.degree != null && coach.degree!.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.space4),
                                Text(coach.degree!, style: AppTheme.caption.copyWith(fontSize: 11)),
                              ],
                              if (coach.achievements != null && coach.achievements!.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.space2),
                                Text(
                                  'Achievements: ${coach.achievements}',
                                  style: AppTheme.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ],
                              if (coach.phone != null && coach.phone!.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.space4),
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
    final degreeController = TextEditingController(text: coach.degree ?? '');
    final expController = TextEditingController(text: coach.experience ?? '');
    final specController = TextEditingController(text: coach.speciality ?? '');
    final achController = TextEditingController(text: coach.achievements ?? '');
    XFile? newPhotoFile;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          Future<void> pickImage(ImageSource source) async {
            final file = await picker.pickImage(source: source, imageQuality: 70);
            if (file != null) {
              setState(() {
                newPhotoFile = file;
              });
            }
          }

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) {
              return;
            }

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(profileRepositoryProvider);
              String? photoUrl = coach.photoUrl;

              if (newPhotoFile != null) {
                photoUrl = await repo.uploadCoachPhoto(newPhotoFile!);
                if (coach.photoUrl != null && coach.photoUrl!.isNotEmpty) {
                  try {
                    await ref.read(supabaseClientProvider).storage.from('coach_photos').remove([coach.photoUrl!]);
                  } catch (_) {}
                }
              }

              await repo.updateCoachProfile(
                coachId: coach.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? '' : phoneController.text.trim(),
                email: emailController.text.trim(),
                degree: degreeController.text.trim().isEmpty ? null : degreeController.text.trim(),
                experience: expController.text.trim().isEmpty ? null : expController.text.trim(),
                speciality: specController.text.trim().isEmpty ? null : specController.text.trim(),
                achievements: achController.text.trim().isEmpty ? null : achController.text.trim(),
                photoUrl: photoUrl,
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
                    // Photo selector
                    Center(
                      child: GestureDetector(
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
                                      pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_rounded),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 2),
                          ),
                          child: newPhotoFile != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(newPhotoFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : coach.photoUrl != null
                                  ? ClipOval(
                                      child: Consumer(
                                        builder: (context, ref, child) {
                                          final bytesAsync = ref.watch(coachPhotoBytesProvider(coach.photoUrl!));
                                          return bytesAsync.when(
                                            data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
                                            loading: () => const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                                            error: (e, s) => const Icon(Icons.person_rounded),
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.add_a_photo_outlined, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    TextFormField(
                      controller: nameController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Email Address *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter email';
                        }
                        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                          if (!phoneRegex.hasMatch(val.trim())) {
                            return 'Enter a valid phone number (7-15 digits)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: degreeController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Degree / Qualification'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: expController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Coaching Experience'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: specController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Speciality'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: achController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Special Achievements'),
                      maxLines: 2,
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
            if (!formKey.currentState!.validate()) {
              return;
            }

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
                      if (val == null || val.isEmpty) {
                        return 'Enter password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
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
    final degreeController = TextEditingController();
    final expController = TextEditingController();
    final specController = TextEditingController();
    final achController = TextEditingController();
    XFile? photoFile;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          Future<void> pickImage(ImageSource source) async {
            final file = await picker.pickImage(source: source, imageQuality: 70);
            if (file != null) {
              setState(() {
                photoFile = file;
              });
            }
          }

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) {
              return;
            }

            setState(() {
              _isSaving = true;
            });

            try {
              final repo = ref.read(profileRepositoryProvider);
              String? photoUrl;
              if (photoFile != null) {
                photoUrl = await repo.uploadCoachPhoto(photoFile!);
              }

              await repo.createCoachUser(
                name: nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text,
                degree: degreeController.text.trim().isEmpty ? null : degreeController.text.trim(),
                experience: expController.text.trim().isEmpty ? null : expController.text.trim(),
                speciality: specController.text.trim().isEmpty ? null : specController.text.trim(),
                achievements: achController.text.trim().isEmpty ? null : achController.text.trim(),
                photoUrl: photoUrl,
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
                    // Photo selector
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (bctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt_rounded),
                                    title: const Text('Capture Camera'),
                                    onTap: () {
                                      Navigator.of(bctx).pop();
                                      pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_rounded),
                                    title: const Text('Choose Library'),
                                    onTap: () {
                                      Navigator.of(bctx).pop();
                                      pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 2),
                          ),
                          child: photoFile != null
                              ? ClipOval(
                                  child: Image.file(File(photoFile!.path), fit: BoxFit.cover),
                                )
                              : const Icon(Icons.add_a_photo_outlined, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    TextFormField(
                      controller: nameController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Email Address *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter email';
                        }

                        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                          if (!phoneRegex.hasMatch(val.trim())) {
                            return 'Enter a valid phone number (7-15 digits)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: degreeController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Degree / Qualification'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: expController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Coaching Experience'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: specController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Speciality'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: achController,
                      style: AppTheme.body1,
                      decoration: const InputDecoration(labelText: 'Special Achievements'),
                      maxLines: 2,
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
                        if (val == null || val.isEmpty) {
                          return 'Enter password';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
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

  Widget _buildCoachPhoto(WidgetRef ref, String? path, BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.primary;
    if (path == null || path.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: fallbackColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(color: fallbackColor.withValues(alpha: 0.15)),
        ),
        child: Icon(Icons.sports_rounded, color: fallbackColor, size: 24),
      );
    }

    final bytesAsync = ref.watch(coachPhotoBytesProvider(path));
    return bytesAsync.when(
      data: (bytes) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          border: Border.all(color: AppTheme.darkBorder),
        ),
      ),
      loading: () => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        child: const Center(
          child: SizedBox(
            height: 14, width: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentLime),
          ),
        ),
      ),
      error: (err, stack) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        child: const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
      ),
    );
  }

  Widget _infoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        text,
        style: AppTheme.overline.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}