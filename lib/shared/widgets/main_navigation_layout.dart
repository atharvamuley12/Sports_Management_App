import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../core/theme/theme.dart';

class MainNavigationLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationLayout({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends ConsumerState<MainNavigationLayout> {
  // Track horizontal drag for swipe navigation
  double _dragStartX = 0.0;
  double _dragStartY = 0.0;
  double _dragDeltaX = 0.0;
  double _dragDeltaY = 0.0;
  bool _isDragging = false;
  bool _decided = false; // Once we decide it's vertical scroll, stop tracking

  // Minimum horizontal distance to count as a valid swipe
  static const double _minSwipeDistance = 100.0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    if (profile == null) {
      return Scaffold(body: widget.child);
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
            const _NavDestination(
              route: '/settings',
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Settings',
            ),
          ];

    // Determine current index
    int currentIndex = destinations.indexWhere((d) => d.route == location);
    if (currentIndex == -1) {
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
    final bottomNavBg = isDark ? const Color(0xFF0C0E12) : const Color(0xFF1B313F);
    final activeColor = isDark ? const Color(0xFFD4A017) : const Color(0xFFE5B02E);
    final inactiveColor = isDark ? AppTheme.textMuted : const Color(0xFFE5E7EB);

    return Scaffold(
      body: Listener(
        // Listener uses raw PointerEvents — doesn't participate in gesture arena
        // so it won't conflict with scrolling, tapping, or any other gestures.
        onPointerDown: (event) {
          _dragStartX = event.position.dx;
          _dragStartY = event.position.dy;
          _dragDeltaX = 0;
          _dragDeltaY = 0;
          _isDragging = true;
          _decided = false;
        },
        onPointerMove: (event) {
          if (!_isDragging || _decided) return;
          _dragDeltaX = event.position.dx - _dragStartX;
          _dragDeltaY = event.position.dy - _dragStartY;

          // Once the user has moved enough, decide: is this a horizontal swipe or vertical scroll?
          final totalDist = _dragDeltaX.abs() + _dragDeltaY.abs();
          if (totalDist > 20) {
            if (_dragDeltaY.abs() > _dragDeltaX.abs()) {
              // Predominantly vertical → this is a scroll, stop tracking
              _isDragging = false;
              _decided = true;
            }
          }
        },
        onPointerUp: (event) {
          if (!_isDragging) return;
          _isDragging = false;
          _decided = true;

          // Only navigate if the swipe was predominantly horizontal and long enough
          if (_dragDeltaX.abs() > _dragDeltaY.abs() && _dragDeltaX.abs() > _minSwipeDistance) {
            if (_dragDeltaX > 0) {
              // Swiped left-to-right → go to LEFT item (previous tab)
              if (currentIndex > 0) {
                context.go(destinations[currentIndex - 1].route);
              }
            } else {
              // Swiped right-to-left → go to RIGHT item (next tab)
              if (currentIndex < destinations.length - 1) {
                context.go(destinations[currentIndex + 1].route);
              }
            }
          }
        },
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavBg,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : const Color(0xFF284456),
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
