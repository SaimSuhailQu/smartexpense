import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartexpense/utils/model_parsing.dart';

void main() {
  group('parseModelDate', () {
    test('parses Firestore Timestamp', () {
      final date = DateTime(2026, 3, 15, 10, 30);
      expect(parseModelDate(Timestamp.fromDate(date)), date);
    });

    test('parses int millis since epoch', () {
      final date = DateTime(2025, 1, 31);
      expect(
        parseModelDate(date.millisecondsSinceEpoch),
        DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch),
      );
    });

    test('parses ISO-8601 string', () {
      expect(parseModelDate('2026-10-19T11:00:00.000'), DateTime(2026, 10, 19, 11, 0));
    });

    test('throws FormatException on garbage instead of inventing today', () {
      expect(() => parseModelDate({'weird': 'shape'}), throwsFormatException);
      expect(() => parseModelDate(null), throwsFormatException);
      expect(() => parseModelDate('not-a-date'), throwsFormatException);
      expect(() => parseModelDate(12.5), throwsFormatException);
    });
  });
}
