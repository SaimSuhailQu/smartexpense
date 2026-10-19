import 'package:flutter_test/flutter_test.dart';
import 'package:smartexpense/utils/date_utils.dart';

void main() {
  group('addMonthsClamped', () {
    test('Jan 31 + 1 month clamps to Feb 28 (no skip to March)', () {
      expect(addMonthsClamped(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 28));
    });

    test('leap-year Feb 29 + 12 months clamps to Feb 28', () {
      expect(addMonthsClamped(DateTime(2024, 2, 29), 12), DateTime(2025, 2, 28));
    });

    test('normal months are unaffected', () {
      expect(addMonthsClamped(DateTime(2026, 3, 15), 1), DateTime(2026, 4, 15));
      expect(addMonthsClamped(DateTime(2026, 10, 19), 3), DateTime(2027, 1, 19));
    });

    test('year boundary rolls over', () {
      expect(addMonthsClamped(DateTime(2026, 12, 10), 1), DateTime(2027, 1, 10));
    });

    test('preserves time components', () {
      expect(
        addMonthsClamped(DateTime(2025, 1, 31, 14, 30, 5), 1),
        DateTime(2025, 2, 28, 14, 30, 5),
      );
    });
  });
}
