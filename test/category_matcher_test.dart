import 'package:flutter_test/flutter_test.dart';
import 'package:smartexpense/utils/category_matcher.dart';

void main() {
  group('normalizeCategoryName', () {
    test('case, spacing and punctuation are ignored', () {
      expect(normalizeCategoryName('  FOOD  '), 'food');
      expect(normalizeCategoryName('Food & Dining'), 'food');
      expect(normalizeCategoryName('Food and Dining'), 'food');
      expect(normalizeCategoryName('Transport'), 'transport');
    });

    test('synonyms resolve to the same canonical name', () {
      expect(normalizeCategoryName('Dining'), 'food');
      expect(normalizeCategoryName('Utility'), 'utilities');
      expect(normalizeCategoryName('Transportation'), 'transport');
      expect(normalizeCategoryName('Grocery'), 'groceries');
      expect(normalizeCategoryName('Healthcare'), 'health');
    });

    test('empty and punctuation-only names normalize to empty', () {
      expect(normalizeCategoryName(''), '');
      expect(normalizeCategoryName('  &  '), '');
    });
  });

  group('categorySimilarity', () {
    test('identical names score 1.0', () {
      expect(categorySimilarity('Food', 'Food'), 1.0);
      expect(categorySimilarity('Food', 'food'), 1.0);
      expect(categorySimilarity('Food', 'Food & Dining'), 1.0);
    });

    test('typos and spelling variants score above the threshold', () {
      expect(
        categorySimilarity('Food', 'Foods'),
        greaterThanOrEqualTo(kCategorySimilarityThreshold),
      );
      expect(
        categorySimilarity('Transport', 'Transportation'),
        greaterThanOrEqualTo(kCategorySimilarityThreshold),
      );
      expect(
        categorySimilarity('Utilities', 'Utility'),
        greaterThanOrEqualTo(kCategorySimilarityThreshold),
      );
    });

    test('genuinely different names score below the threshold', () {
      expect(
        categorySimilarity('Food', 'Groceries'),
        lessThan(kCategorySimilarityThreshold),
      );
      expect(
        categorySimilarity('Travel', 'Transport'),
        lessThan(kCategorySimilarityThreshold),
      );
      expect(
        categorySimilarity('Rent', 'Entertainment'),
        lessThan(kCategorySimilarityThreshold),
      );
      expect(
        categorySimilarity('Food', 'Shopping'),
        lessThan(kCategorySimilarityThreshold),
      );
    });
  });

  group('tokenSimilarity', () {
    test('subset names score high', () {
      expect(tokenSimilarity('Food', 'Food & Dining'), 0.9);
    });

    test('disjoint names score zero', () {
      expect(tokenSimilarity('Food', 'Groceries'), 0.0);
    });
  });

  group('findDuplicateGroups', () {
    test('groups case, punctuation and spelling duplicates together', () {
      final groups = findDuplicateGroups([
        'Food',
        'food',
        'Food & Dining',
        'Groceries',
        'groceries ',
        'Transport',
        'Transportation',
        'Rent',
      ]);
      // NOTE: Dart sets compare by identity, so compare membership with
      // containsAll instead of contains({...}).
      final asSets = groups.map((g) => g.toSet()).toList();
      expect(asSets.length, 3);
      expect(
        asSets.any((s) => s.containsAll(['Food', 'food', 'Food & Dining'])),
        isTrue,
      );
      expect(
        asSets.any((s) => s.containsAll(['Groceries', 'groceries '])),
        isTrue,
      );
      expect(
        asSets.any((s) => s.containsAll(['Transport', 'Transportation'])),
        isTrue,
      );
    });

    test('returns empty when nothing is duplicated', () {
      expect(
        findDuplicateGroups(['Food', 'Groceries', 'Transport', 'Rent']),
        isEmpty,
      );
    });

    test('empty input returns empty', () {
      expect(findDuplicateGroups([]), isEmpty);
    });
  });

  group('findBestMatch', () {
    const existing = ['Food', 'Groceries', 'Transport'];

    test('finds a typo variant', () {
      expect(findBestMatch('Foods', existing), 'Food');
      expect(findBestMatch('Transpor', existing), 'Transport');
    });

    test('finds a same-meaning name', () {
      // "Dining Out" means Food but is not the same name after cleanup.
      expect(findBestMatch('Dining Out', existing), 'Food');
    });

    test('returns null when nothing is close', () {
      expect(findBestMatch('Zebra', existing), isNull);
    });

    test('exact duplicates are not reported as fuzzy matches', () {
      expect(findBestMatch('food', existing), isNull);
      // Synonyms normalize to the same name, so these are exact duplicates
      // too — the add-category path handles them, not the fuzzy match.
      expect(findBestMatch('Dining', existing), isNull);
      expect(findBestMatch('Transportation', existing), isNull);
    });
  });

  group('pickCanonical', () {
    test('most-used member wins', () {
      expect(
        pickCanonical(
          ['Foods', 'Food'],
          usageCounts: {'Foods': 3, 'Food': 10},
        ),
        'Food',
      );
    });

    test('ties break by input order', () {
      expect(pickCanonical(['Foods', 'Food']), 'Foods');
    });
  });
}
