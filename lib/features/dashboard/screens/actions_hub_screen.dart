import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ActionsHubScreen extends ConsumerWidget {
  const ActionsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hubItems = [
      _HubItem(
        title: 'Attendance',
        subtitle: 'Log and track daily player attendance lists',
        icon: Icons.fact_check_rounded,
        color: AppTheme.accentTeal,
        route: '/attendance',
      ),
      _HubItem(
        title: 'Fee Ledger',
        subtitle: 'Manage monthly student dues and registries',
        icon: Icons.account_balance_wallet_rounded,
        color: AppTheme.accentLime,
        route: '/fees',
      ),
      _HubItem(
        title: 'Expenses Log',
        subtitle: 'Record academy bills, rents, and equipment fees',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.errorRed,
        route: '/expenses',
      ),
      _HubItem(
        title: 'Financial Reports',
        subtitle: 'Analyze overall revenue, expenses, and growth',
        icon: Icons.bar_chart_rounded,
        color: AppTheme.accentPurple,
        route: '/reports',
      ),
      _HubItem(
        title: 'Coaches Roster',
        subtitle: 'Manage academy staff and account accesses',
        icon: Icons.sports_rounded,
        color: AppTheme.infoBlue,
        route: '/users',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academy Hub'),
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Center',
                    style: AppTheme.caption.copyWith(
                      color: isDark ? AppTheme.accentLime : AppTheme.accentLimeDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    'Access management modules and generate reports.',
                    style: AppTheme.body2,
                  ),
                  const SizedBox(height: AppTheme.space20),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = hubItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: AppCard(
                      accentColor: item.color,
                      onTap: () => context.push(item.route),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space12),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppTheme.radius12),
                              border: Border.all(
                                color: item.color.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: isDark ? item.color : theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTheme.subtitle1.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space4),
                                Text(
                                  item.subtitle,
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.textTheme.bodySmall?.color ?? AppTheme.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: hubItems.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.space24),
          ),
        ],
      ),
    );
  }
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _HubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
