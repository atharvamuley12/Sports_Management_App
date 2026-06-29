import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

// ═══════════════════════════════════════════════════════════════════
// APP CARD — Consistent card wrapper
// ═══════════════════════════════════════════════════════════════════

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.borderRadius = AppTheme.radius16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outline;

    final borderSide = accentColor != null
        ? BorderSide(color: accentColor!.withValues(alpha: isDark ? 0.2 : 0.4), width: 0.8)
        : BorderSide(color: borderColor, width: 0.8);

    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    if (onTap != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: (accentColor ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.08 : 0.12),
            highlightColor: (accentColor ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.04 : 0.06),
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.fromBorderSide(borderSide),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.fromBorderSide(borderSide),
        boxShadow: shadows,
      ),
      padding: padding,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP EMPTY STATE — Friendly empty state with optional CTA
// ═══════════════════════════════════════════════════════════════════

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppTheme.space20),
            Text(
              title,
              style: AppTheme.subtitle1.copyWith(color: theme.textTheme.titleMedium?.color ?? AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              subtitle,
              style: AppTheme.body2.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.space24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP LOADING STATE — Shimmer placeholder cards
// ═══════════════════════════════════════════════════════════════════

class AppLoadingState extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const AppLoadingState({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 80,
  });

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final placeholderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final placeholderSubtleColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space12),
          itemBuilder: (context, index) {
            return Container(
              height: widget.itemHeight,
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radius16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: placeholderColor.withValues(alpha: _animation.value),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: placeholderColor.withValues(alpha: _animation.value),
                            borderRadius: BorderRadius.circular(AppTheme.radius6),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Container(
                          height: 10,
                          width: 90,
                          decoration: BoxDecoration(
                            color: placeholderSubtleColor.withValues(alpha: _animation.value),
                            borderRadius: BorderRadius.circular(AppTheme.radius6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP ERROR STATE — Friendly error with retry
// ═══════════════════════════════════════════════════════════════════

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: AppTheme.space20),
            Text(
              'Something went wrong',
              style: AppTheme.subtitle1.copyWith(color: theme.textTheme.titleMedium?.color ?? AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              message,
              style: AppTheme.caption,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.space20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyLarge?.color,
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP SEARCH BAR — Consistent search input
// ═══════════════════════════════════════════════════════════════════

class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius14),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius14),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP SECTION HEADER — Consistent section title
// ═══════════════════════════════════════════════════════════════════

class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: AppTheme.space8),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTheme.overline.copyWith(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        if (trailing != null) ...[trailing as Widget],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP STATUS CHIP — Color-coded status badges
// ═══════════════════════════════════════════════════════════════════

class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  // Convenience factories
  factory AppStatusChip.active() => const AppStatusChip(
    label: 'ACTIVE',
    color: AppTheme.successGreen,
    icon: Icons.check_circle_outline_rounded,
  );

  // Inactive state helper
  factory AppStatusChip.inactive() => const AppStatusChip(
    label: 'INACTIVE',
    color: AppTheme.errorRed,
    icon: Icons.cancel_outlined,
  );

  factory AppStatusChip.present() => const AppStatusChip(
    label: 'PRESENT',
    color: AppTheme.successGreen,
  );

  factory AppStatusChip.absent() => const AppStatusChip(
    label: 'ABSENT',
    color: AppTheme.errorRed,
  );

  factory AppStatusChip.paid() => const AppStatusChip(
    label: 'PAID',
    color: AppTheme.successGreen,
    icon: Icons.check_rounded,
  );

  factory AppStatusChip.pending() => const AppStatusChip(
    label: 'PENDING',
    color: AppTheme.warningAmber,
    icon: Icons.schedule_rounded,
  );

  factory AppStatusChip.restricted() => const AppStatusChip(
    label: 'RESTRICTED',
    color: AppTheme.errorRed,
    icon: Icons.lock_rounded,
  );

  factory AppStatusChip.sport(String sport) => AppStatusChip(
    label: sport.toUpperCase(),
    color: sport == 'cricket' ? AppTheme.accentLime : AppTheme.accentTeal,
    icon: sport == 'cricket' ? Icons.sports_cricket : Icons.sports_soccer,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.black : color),
            const SizedBox(width: AppTheme.space4),
          ],
          Text(
            label,
            style: AppTheme.overline.copyWith(
              color: filled ? Colors.black : color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP ICON BUTTON — Rounded icon button with background
// ═══════════════════════════════════════════════════════════════════

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? (theme.cardTheme.color ?? theme.colorScheme.surface);
    final iconColor = color ?? theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    final button = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppTheme.radius12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(color: theme.colorScheme.outline, width: 0.8),
          ),
          child: Icon(icon, size: size, color: iconColor),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP GRADIENT ICON — Icon with gradient background
// ═══════════════════════════════════════════════════════════════════

class AppGradientIcon extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final double size;
  final double padding;
  final double borderRadius;

  const AppGradientIcon({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 20,
    this.padding = AppTheme.space10,
    this.borderRadius = AppTheme.radius12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, size: size, color: Colors.black),
    );
  }
}
