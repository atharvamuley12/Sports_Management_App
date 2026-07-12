import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/export_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/activity_controller.dart';
import '../../../shared/models/activity.dart';
import '../../auth/repositories/profile_repository.dart';

class ActivityListScreen extends ConsumerStatefulWidget {
  const ActivityListScreen({super.key});

  @override
  ConsumerState<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends ConsumerState<ActivityListScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCoachId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final isCoach = profile?.isCoach ?? false;

    // If coach, always filter by their ID
    final coachId = isCoach ? profile?.id : _selectedCoachId;

    final activitiesAsync = ref.watch(activityListProvider((coachId: coachId, date: _selectedDate)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Activities'),
        actions: [
          if (!isCoach)
            _ExportButton(
              activitiesAsync: activitiesAsync,
              selectedDate: _selectedDate,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
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
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: AppTheme.heading3,
                  ),
                ),
                if (!isCoach)
                  _CoachFilter(
                    selectedId: _selectedCoachId,
                    onChanged: (id) => setState(() => _selectedCoachId = id),
                  ),
              ],
            ),
          ),
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          'No activities planned for this day',
                          style: AppTheme.subtitle1.copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityCard(activity: activity);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: isCoach
          ? FloatingActionButton(
              onPressed: () => context.push('/activities/new', extra: _selectedDate),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(authControllerProvider).profile;
    final canEdit = profile?.id == activity.coachId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      decoration: AppTheme.premiumCard(isDark: isDark),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.title, style: AppTheme.heading3),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'By ${activity.coachName}',
                        style: AppTheme.caption.copyWith(color: AppTheme.accentGold),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: activity.status),
                if (canEdit)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/activities/edit', extra: activity);
                      } else if (value == 'delete') {
                        _confirmDelete(context, ref);
                      } else {
                        ref.read(activityControllerProvider.notifier).updateStatus(activity.id, value);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                      const PopupMenuItem(value: 'cancelled', child: Text('Mark Cancelled')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              activity.description,
              style: AppTheme.body2,
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Created: ${DateFormat('h:mm a').format(activity.createdAt)}',
                  style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(activityControllerProvider.notifier).deleteActivity(activity.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = AppTheme.successGreen;
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        break;
      default:
        color = AppTheme.warningAmber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.overline.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}

class _CoachFilter extends ConsumerWidget {
  final String? selectedId;
  final Function(String?) onChanged;

  const _CoachFilter({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachesAsync = ref.watch(coachesListProvider);

    return coachesAsync.when(
      data: (coaches) => DropdownButton<String?>(
        value: selectedId,
        hint: const Text('All Coaches', style: TextStyle(fontSize: 12)),
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Coaches', style: TextStyle(fontSize: 12))),
          ...coaches.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.fullName, style: const TextStyle(fontSize: 12)),
              )),
        ],
        onChanged: onChanged,
      ),
      loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Icon(Icons.error, size: 20),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final AsyncValue<List<Activity>> activitiesAsync;
  final DateTime selectedDate;

  const _ExportButton({required this.activitiesAsync, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download_rounded),
      tooltip: 'Export Activities',
      onSelected: (value) async {
        final data = activitiesAsync.value;
        if (data == null || data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No activities to export')),
          );
          return;
        }

        final title = 'Coaching Activities - ${DateFormat('yyyy-MM-dd').format(selectedDate)}';
        const headers = ['Coach', 'Title', 'Status', 'Description', 'Created At'];
        final rows = data.map<List<String>>((a) => [
          a.coachName,
          a.title,
          a.status.toUpperCase(),
          a.description,
          DateFormat('h:mm a').format(a.createdAt),
        ]).toList();

        final isPdf = value.contains('pdf');
        final isShare = value.startsWith('share');

        await ExportHelper.exportData(
          context: context,
          fileName: 'activities_report',
          title: title,
          headers: headers,
          rows: rows,
          exportAsPdf: isPdf,
          share: isShare,
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'download_pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: AppTheme.errorRed, size: 18),
              SizedBox(width: 8),
              Text('Download PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share_pdf',
          child: Row(
            children: [
              Icon(Icons.share_rounded, color: AppTheme.errorRed, size: 18),
              SizedBox(width: 8),
              Text('Share PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'download_excel',
          child: Row(
            children: [
              Icon(Icons.grid_on_rounded, color: AppTheme.successGreen, size: 18),
              SizedBox(width: 8),
              Text('Download Excel'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share_excel',
          child: Row(
            children: [
              Icon(Icons.share_rounded, color: AppTheme.successGreen, size: 18),
              SizedBox(width: 8),
              Text('Share Excel'),
            ],
          ),
        ),
      ],
    );
  }
}
