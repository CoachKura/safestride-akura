// lib/theme/design_system_examples.dart
//
// AKURA SafeStride Design System - Usage Examples
// 
// This file contains example widgets demonstrating how to use
// the design system components. Use as reference when building screens.

import 'package:flutter/material.dart';
import 'theme.dart';

/// Example: Primary Card Component
/// Usage: Stats display, workout summaries
class ExamplePrimaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  const ExamplePrimaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.iconColor = AppColors.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.md,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.defaultRadius,
        boxShadow: AppShadows.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(icon, color: iconColor, size: AppSpacing.iconSize),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.statValue),
          Text(unit, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

/// Example: Hero Card Component
/// Usage: Featured content, weekly summary
class ExampleHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback? onTap;

  const ExampleHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppPadding.lg,
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: AppRadius.largeRadius,
          boxShadow: AppShadows.modalShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.statValue.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.pillRadius,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: AISRI Zone Badge
/// Usage: Zone indicators in workouts
class ExampleZoneBadge extends StatelessWidget {
  final String zone;
  final bool isActive;

  const ExampleZoneBadge({
    super.key,
    required this.zone,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getZoneColor(zone);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: color,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            zone.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Example: Action Button (Primary CTA)
/// Usage: Start workout, save, submit
class ExampleActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const ExampleActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMedium),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconSize),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label, style: AppTextStyles.labelLarge),
              ],
            ),
    );
  }
}

/// Example: Stat Row (Multiple metrics)
/// Usage: Workout summary, dashboard
class ExampleStatRow extends StatelessWidget {
  final List<StatItem> stats;

  const ExampleStatRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Column(
            children: [
              Text(stat.value, style: AppTextStyles.statValue),
              const SizedBox(height: AppSpacing.xs),
              Text(
                stat.label,
                style: AppTextStyles.statLabel,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class StatItem {
  final String value;
  final String label;

  const StatItem({required this.value, required this.label});
}

/// Example: Section Header
/// Usage: Section titles with action
class ExampleSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const ExampleSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Example: Workout List Item
/// Usage: Upcoming workouts, history
class ExampleWorkoutListItem extends StatelessWidget {
  final String title;
  final String distance;
  final String zone;
  final String duration;
  final bool isCompleted;
  final VoidCallback? onTap;

  const ExampleWorkoutListItem({
    super.key,
    required this.title,
    required this.distance,
    required this.zone,
    required this.duration,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.defaultRadius,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: AppPadding.md,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppColors.success.withOpacity(0.15) 
                : AppColors.primaryOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.directions_run,
            color: isCompleted ? AppColors.success : AppColors.primaryOrange,
          ),
        ),
        title: Text(title, style: AppTextStyles.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              Text(
                '$distance • Zone $zone • $duration',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// Example: Empty State
/// Usage: No data screens
class ExampleEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ExampleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.xl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
