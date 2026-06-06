/// Consistent spacing tokens for layout and component spacing
///
/// Design Philosophy:
/// - 8px base grid system for consistent rhythm
/// - Semantic naming for common UI patterns
/// - Follows Material Design spacing guidelines
/// - Ensures visual consistency across the application
class AppSpacing {
  // ==================== BASE SPACING SCALE ====================
  // Using 8px base grid (4px for micro-spacing)

  /// 4px - Micro spacing for very tight groupings
  static const double xs = 4.0;

  /// 8px - Extra small spacing for tight groupings
  static const double sm = 8.0;

  /// 12px - Small-medium spacing for related elements
  static const double md = 12.0;

  /// 16px - Medium spacing (base unit) for standard gaps
  static const double lg = 16.0;

  /// 20px - Medium-large spacing for section padding
  static const double xl = 20.0;

  /// 24px - Large spacing for card padding and major sections
  static const double xxl = 24.0;

  /// 32px - Extra large spacing for page margins
  static const double xxxl = 32.0;

  /// 48px - Huge spacing for major visual breaks
  static const double huge = 48.0;

  // ==================== SEMANTIC SPACING ====================
  // Named spacing for specific UI patterns

  // Card spacing
  /// Standard padding inside cards (24px)
  static const double cardPadding = xxl;

  /// Compact card padding for dense layouts (16px)
  static const double cardPaddingCompact = lg;

  /// Spacing between cards in a list (12px)
  static const double cardGap = md;

  // List item spacing
  /// Horizontal padding for list items (16px)
  static const double listItemPaddingHorizontal = lg;

  /// Vertical padding for list items (12px)
  static const double listItemPaddingVertical = md;

  /// Spacing between list items (8px)
  static const double listItemGap = sm;

  // Page spacing
  /// Horizontal margin for page content (16px)
  static const double pageMarginHorizontal = lg;

  /// Top margin for page content (20px)
  static const double pageMarginTop = xl;

  /// Bottom margin for page content (24px)
  static const double pageMarginBottom = xxl;

  // Section spacing
  /// Spacing between major sections (32px)
  static const double sectionGap = xxxl;

  /// Spacing between subsections (24px)
  static const double subsectionGap = xxl;

  /// Spacing between related items in a section (16px)
  static const double itemGap = lg;

  // Form spacing
  /// Spacing between form fields (16px)
  static const double formFieldGap = lg;

  /// Padding inside input fields (16px horizontal, 16px vertical)
  static const double inputPaddingHorizontal = lg;
  static const double inputPaddingVertical = lg;

  // Button spacing
  /// Horizontal padding for buttons (24px)
  static const double buttonPaddingHorizontal = xxl;

  /// Vertical padding for buttons (16px)
  static const double buttonPaddingVertical = lg;

  /// Spacing between buttons (12px)
  static const double buttonGap = md;

  // Icon spacing
  /// Spacing between icon and text (8px)
  static const double iconTextGap = sm;

  /// Padding around icons in buttons (10px)
  static const double iconPadding = 10.0;

  // ==================== BORDER RADIUS ====================

  /// Extra small border radius (8px) - for tags, chips
  static const double radiusXS = 8.0;

  /// Small border radius (12px) - for small buttons
  static const double radiusSM = 12.0;

  /// Medium border radius (16px) - for buttons, inputs
  static const double radiusMD = 16.0;

  /// Large border radius (20px) - for cards
  static const double radiusLG = 20.0;

  /// Extra large border radius (24px) - for large cards
  static const double radiusXL = 24.0;

  /// Pill border radius (9999px) - for fully rounded elements
  static const double radiusPill = 9999.0;

  // ==================== HELPER METHODS ====================

  /// Returns EdgeInsets for standard card padding
  static EdgeInsets get cardPaddingInsets => const EdgeInsets.all(cardPadding);

  /// Returns EdgeInsets for compact card padding
  static EdgeInsets get cardPaddingCompactInsets => const EdgeInsets.all(cardPaddingCompact);

  /// Returns EdgeInsets for page margins
  static EdgeInsets get pageMarginInsets => const EdgeInsets.symmetric(
    horizontal: pageMarginHorizontal,
    vertical: pageMarginTop,
  );

  /// Returns EdgeInsets for horizontal page margins only
  static EdgeInsets get pageMarginHorizontalInsets => const EdgeInsets.symmetric(
    horizontal: pageMarginHorizontal,
  );

  /// Returns EdgeInsets for list item padding
  static EdgeInsets get listItemPaddingInsets => const EdgeInsets.symmetric(
    horizontal: listItemPaddingHorizontal,
    vertical: listItemPaddingVertical,
  );

  /// Returns EdgeInsets for button padding
  static EdgeInsets get buttonPaddingInsets => const EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontal,
    vertical: buttonPaddingVertical,
  );

  /// Returns EdgeInsets for input field padding
  static EdgeInsets get inputPaddingInsets => const EdgeInsets.symmetric(
    horizontal: inputPaddingHorizontal,
    vertical: inputPaddingVertical,
  );

  /// Returns a SizedBox with vertical spacing
  static SizedBox verticalSpace(double height) => SizedBox(height: height);

  /// Returns a SizedBox with horizontal spacing
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);

  /// Returns a SizedBox with xs vertical spacing (4px)
  static SizedBox get verticalSpaceXS => verticalSpace(xs);

  /// Returns a SizedBox with sm vertical spacing (8px)
  static SizedBox get verticalSpaceSM => verticalSpace(sm);

  /// Returns a SizedBox with md vertical spacing (12px)
  static SizedBox get verticalSpaceMD => verticalSpace(md);

  /// Returns a SizedBox with lg vertical spacing (16px)
  static SizedBox get verticalSpaceLG => verticalSpace(lg);

  /// Returns a SizedBox with xl vertical spacing (20px)
  static SizedBox get verticalSpaceXL => verticalSpace(xl);

  /// Returns a SizedBox with xxl vertical spacing (24px)
  static SizedBox get verticalSpaceXXL => verticalSpace(xxl);

  /// Returns a SizedBox with xxxl vertical spacing (32px)
  static SizedBox get verticalSpaceXXXL => verticalSpace(xxxl);

  /// Returns a SizedBox with xs horizontal spacing (4px)
  static SizedBox get horizontalSpaceXS => horizontalSpace(xs);

  /// Returns a SizedBox with sm horizontal spacing (8px)
  static SizedBox get horizontalSpaceSM => horizontalSpace(sm);

  /// Returns a SizedBox with md horizontal spacing (12px)
  static SizedBox get horizontalSpaceMD => horizontalSpace(md);

  /// Returns a SizedBox with lg horizontal spacing (16px)
  static SizedBox get horizontalSpaceLG => horizontalSpace(lg);

  /// Returns a SizedBox with xl horizontal spacing (20px)
  static SizedBox get horizontalSpaceXL => horizontalSpace(xl);

  /// Returns a SizedBox with xxl horizontal spacing (24px)
  static SizedBox get horizontalSpaceXXL => horizontalSpace(xxl);

  /// Returns a SizedBox with xxxl horizontal spacing (32px)
  static SizedBox get horizontalSpaceXXXL => horizontalSpace(xxxl);
}
