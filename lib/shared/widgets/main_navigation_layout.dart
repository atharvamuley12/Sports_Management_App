import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../core/theme/theme.dart';

class MainNavigationLayout extends ConsumerWidget {
  final Widget child;

  const MainNavigationLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    if (profile == null) {
      return Scaffold(body: child);
    }

    final isAdmin = profile.isAdmin;
    final location = GoRouterState.of(context).matchedLocation;

    // Define items based on role
    final List<_NavDestination> destinations = isAdmin
        ? [
            const _NavDestination(
              route: '/dashboard',
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              label: 'Overview',
            ),
            const _NavDestination(
              route: '/students',
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Students',
            ),
            const _NavDestination(
              route: '/batches',
              icon: Icons.layers_outlined,
              activeIcon: Icons.layers_rounded,
              label: 'Batches',
            ),
            const _NavDestination(
              route: '/hub',
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Hub',
            ),
            const _NavDestination(
              route: '/settings',
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Settings',
            ),
          ]
        : [
            const _NavDestination(
              route: '/dashboard',
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              label: 'Overview',
            ),
            const _NavDestination(
              route: '/students',
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Students',
            ),
            const _NavDestination(
              route: '/attendance',
              icon: Icons.fact_check_outlined,
              activeIcon: Icons.fact_check_rounded,
              label: 'Attendance',
            ),
          ];

    // Determine current index
    int currentIndex = destinations.indexWhere((d) => d.route == location);
    if (currentIndex == -1) {
      // Fallbacks for sub-paths if any are inside the shell
      if (location.startsWith('/students')) {
        currentIndex = 1;
      } else if (location.startsWith('/batches') && isAdmin) {
        currentIndex = 2;
      } else if (location.startsWith('/attendance')) {
        currentIndex = isAdmin ? 3 : 2;
      } else {
        currentIndex = 0;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(destinations.length, (index) {
                final dest = destinations[index];
                final isSelected = index == currentIndex;
                final activeColor = isDark ? AppTheme.accentLime : AppTheme.accentLimeDark;
                final inactiveColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

                return GestureDetector(
                  onTap: () => context.go(dest.route),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? dest.activeIcon : dest.icon,
                            color: isSelected ? activeColor : inactiveColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dest.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? activeColor : inactiveColor,
                          ) ?? TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
