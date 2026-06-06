import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Skeleton loading screens using shimmer effect
///
/// Design Philosophy:
/// - Provide visual feedback during data loading
/// - Match the shape and layout of actual content
/// - Smooth shimmer animation
/// - Themed for both light and dark modes
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading._();

  /// Card shimmer for expense/income cards
  static Widget card({required bool isDark}) {
    return _ShimmerWrapper(
      isDark: isDark,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal,
          vertical: AppSpacing.cardGap / 2,
        ),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _getShimmerBaseColor(isDark),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getShimmerHighlightColor(isDark),
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.horizontalSpaceLG,
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _getShimmerHighlightColor(isDark),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AppSpacing.verticalSpaceSM,
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: _getShimmerHighlightColor(isDark),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalSpaceLG,
            // Amount placeholder
            Container(
              height: 20,
              width: 80,
              decoration: BoxDecoration(
                color: _getShimmerHighlightColor(isDark),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List shimmer for transaction lists
  static Widget list({
    required bool isDark,
    int itemCount = 5,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => card(isDark: isDark),
    );
  }

  /// Chart shimmer for financial charts
  static Widget chart({
    required bool isDark,
    double? height,
  }) {
    return _ShimmerWrapper(
      isDark: isDark,
      child: Container(
        height: height ?? 200,
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal,
          vertical: AppSpacing.cardGap / 2,
        ),
        padding: EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: _getShimmerBaseColor(isDark),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title placeholder
            Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: _getShimmerHighlightColor(isDark),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AppSpacing.verticalSpaceLG,
            // Chart bars
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      height: 60 + (index * 15.0),
                      decoration: BoxDecoration(
                        color: _getShimmerHighlightColor(isDark),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusSM),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Budget card shimmer
  static Widget budgetCard({required bool isDark}) {
    return _ShimmerWrapper(
      isDark: isDark,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal,
          vertical: AppSpacing.cardGap / 2,
        ),
        padding: EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: _getShimmerBaseColor(isDark),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 32,
                  width: 100,
                  decoration: BoxDecoration(
                    color: _getShimmerHighlightColor(isDark),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                ),
                Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: _getShimmerHighlightColor(isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceXL,
            // Progress bar
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getShimmerHighlightColor(isDark),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AppSpacing.verticalSpaceLG,
            // Spent and remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: _getShimmerHighlightColor(isDark),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AppSpacing.verticalSpaceXS,
                    Container(
                      height: 16,
                      width: 70,
                      decoration: BoxDecoration(
                        color: _getShimmerHighlightColor(isDark),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: _getShimmerHighlightColor(isDark),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AppSpacing.verticalSpaceXS,
                    Container(
                      height: 16,
                      width: 70,
                      decoration: BoxDecoration(
                        color: _getShimmerHighlightColor(isDark),
                        borderRadius: BorderRadius.circular(4),
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
  }

  /// Dashboard shimmer (full dashboard skeleton)
  static Widget dashboard({required bool isDark}) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _ShimmerWrapper(
            isDark: isDark,
            child: Container(
              height: 120,
              margin: EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMarginHorizontal,
                vertical: AppSpacing.cardGap,
              ),
              decoration: BoxDecoration(
                color: _getShimmerBaseColor(isDark),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
          ),

          AppSpacing.verticalSpaceLG,

          // Chart section
          chart(isDark: isDark, height: 250),

          AppSpacing.verticalSpaceXL,

          // Recent transactions header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageMarginHorizontal,
            ),
            child: _ShimmerWrapper(
              isDark: isDark,
              child: Container(
                height: 24,
                width: 150,
                decoration: BoxDecoration(
                  color: _getShimmerHighlightColor(isDark),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          AppSpacing.verticalSpaceLG,

          // Transaction list
          list(isDark: isDark, itemCount: 3),
        ],
      ),
    );
  }

  // Helper methods
  static Color _getShimmerBaseColor(bool isDark) {
    return isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight2;
  }

  static Color _getShimmerHighlightColor(bool isDark) {
    return isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight;
  }
}

/// Wrapper widget that applies shimmer effect
class _ShimmerWrapper extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _ShimmerWrapper({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceDark1
          : AppColors.surfaceLight2,
      highlightColor: isDark
          ? AppColors.surfaceDark2.withOpacity(0.5)
          : Colors.white,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}
