import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// Polished error state widget for error scenarios
///
/// Design Philosophy:
/// - Clear error communication with icon and message
/// - Actionable recovery steps
/// - Consistent visual language
/// - WCAG AA compliant colors
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData? icon;
  final List<String>? recoverySteps;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.icon,
    this.recoverySteps,
  });

  /// Factory: Network error
  factory ErrorState.network({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      title: 'Connection Error',
      message: 'Unable to connect to the server. Please check your internet connection.',
      icon: Icons.wifi_off_outlined,
      actionLabel: 'Retry',
      onActionPressed: onRetry,
      recoverySteps: [
        'Check your internet connection',
        'Try again in a few moments',
        'Contact support if the problem persists',
      ],
    );
  }

  /// Factory: Data loading error
  factory ErrorState.dataLoading({
    VoidCallback? onRetry,
    String? errorDetails,
  }) {
    return ErrorState(
      title: 'Failed to Load Data',
      message: errorDetails ?? 'Something went wrong while loading your data.',
      icon: Icons.error_outline,
      actionLabel: 'Retry',
      onActionPressed: onRetry,
      recoverySteps: [
        'Pull down to refresh',
        'Check your internet connection',
        'Try again later',
      ],
    );
  }

  /// Factory: Authentication error
  factory ErrorState.authentication({
    VoidCallback? onSignIn,
  }) {
    return ErrorState(
      title: 'Authentication Required',
      message: 'Your session has expired. Please sign in again.',
      icon: Icons.lock_outline,
      actionLabel: 'Sign In',
      onActionPressed: onSignIn,
    );
  }

  /// Factory: Permission error
  factory ErrorState.permission({
    String? permissionType,
    VoidCallback? onRequestPermission,
  }) {
    return ErrorState(
      title: 'Permission Required',
      message: permissionType != null
          ? 'This feature requires $permissionType permission.'
          : 'This feature requires additional permissions.',
      icon: Icons.block_outlined,
      actionLabel: 'Grant Permission',
      onActionPressed: onRequestPermission,
      recoverySteps: [
        'Tap the button below to grant permission',
        'Enable the required permission in settings',
      ],
    );
  }

  /// Factory: Server error
  factory ErrorState.server({
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      title: 'Server Error',
      message: 'The server encountered an error. Please try again later.',
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Retry',
      onActionPressed: onRetry,
      recoverySteps: [
        'Wait a few moments',
        'Try again',
        'Contact support if the issue persists',
      ],
    );
  }

  /// Factory: Generic error
  factory ErrorState.generic({
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return ErrorState(
      title: 'Something Went Wrong',
      message: errorMessage ?? 'An unexpected error occurred.',
      icon: Icons.error_outline,
      actionLabel: 'Retry',
      onActionPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorLight : AppColors.error;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal * 2,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon with background
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 64,
                color: errorColor,
              ),
            ),

            AppSpacing.verticalSpaceXXL,

            // Error title
            Text(
              title,
              style: AppTypography.headingMedium(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            AppSpacing.verticalSpaceMD,

            // Error message
            Text(
              message,
              style: AppTypography.bodyMedium(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
            ),

            // Recovery steps (if provided)
            if (recoverySteps != null && recoverySteps!.isNotEmpty) ...[
              AppSpacing.verticalSpaceXXL,
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark1
                      : AppColors.surfaceLight1,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(
                    color: (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                        .withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'What you can try:',
                      style: AppTypography.labelLarge(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    AppSpacing.verticalSpaceSM,
                    ...recoverySteps!.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key < recoverySteps!.length - 1
                              ? AppSpacing.sm
                              : 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: AppTypography.bodySmall(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTypography.bodySmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Action button
            if (actionLabel != null && onActionPressed != null) ...[
              AppSpacing.verticalSpaceXXL,
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
