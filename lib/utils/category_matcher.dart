/// Smart duplicate detection for expense categories.
///
/// Pure Dart (no Flutter imports) so the matching logic can be unit-tested
/// in isolation.
///
/// Why this exists: categories used to be keyed by their exact display name,
/// so "Food", "food", "Food " and "Food & Dining" all lived side by side as
/// separate categories, splitting charts, budgets and filters. The matcher
/// below catches the three ways that happens:
///
/// 1. Exact-after-cleanup duplicates — same name up to case, spacing or
///    punctuation ("Food" vs "food", "Food & Dining" vs "Food").
/// 2. Typos and spelling variants — Jaro-Winkler similarity
///    ("Food" vs "Foods", "Transport" vs "Transportation").
/// 3. Same-meaning names — a small, conservative synonym map applied at
///    token level ("Dining" vs "Food", "Utility" vs "Utilities").
///
/// Deliberately NOT merged: names that merely sound alike but mean different
/// things ("Food" vs "Groceries", "Travel" vs "Transport"). The synonym map
/// is intentionally small; extend it only for pairs that are the same
/// category in plain language, never for merely related ones.
library;

/// Default similarity cut-off. 0.85 groups clear typos and spelling
/// variants while keeping genuinely different names apart.
const double kCategorySimilarityThreshold = 0.85;

/// Token-level synonyms: each key means the same category as its value.
/// Applied during normalization, before any comparison.
const Map<String, String> _categorySynonyms = {
  // Eating out is food, not a separate category.
  'dining': 'food',
  'eating': 'food',
  'restaurant': 'food',
  'restaurants': 'food',
  'takeaway': 'food',
  // Getting around.
  'transportation': 'transport',
  'commute': 'transport',
  // Household bills.
  'utility': 'utilities',
  'bills': 'utilities',
  // Where food is bought.
  'grocery': 'groceries',
  'supermarket': 'groceries',
  // Health.
  'healthcare': 'health',
  'medical': 'health',
  // Fun.
  'leisure': 'entertainment',
};

/// Canonical form of a category name for comparison: lower-cased, trimmed,
/// punctuation stripped, filler words dropped, synonyms resolved, tokens
/// de-duplicated. "Food & Dining" and "food" both normalize to "food".
String normalizeCategoryName(String name) {
  final cleaned = name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ');
  final tokens = cleaned
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .map((token) => _categorySynonyms[token] ?? token)
      .where((token) => token != 'and' && token != 'the')
      .toSet()
      .toList();
  return tokens.join(' ');
}

/// Tokens of a category name, after normalization.
List<String> categoryTokens(String name) {
  final normalized = normalizeCategoryName(name);
  if (normalized.isEmpty) return const [];
  return normalized.split(' ');
}

/// Jaro similarity between two strings (0.0 – 1.0).
double jaroSimilarity(String s1, String s2) {
  if (s1 == s2) return 1.0;
  final len1 = s1.length;
  final len2 = s2.length;
  if (len1 == 0 || len2 == 0) return 0.0;

  var matchDistance = (len1 > len2 ? len1 : len2) ~/ 2 - 1;
  if (matchDistance < 0) matchDistance = 0;

  final s1Matches = List<bool>.filled(len1, false);
  final s2Matches = List<bool>.filled(len2, false);
  var matches = 0;

  for (var i = 0; i < len1; i++) {
    final start = i - matchDistance < 0 ? 0 : i - matchDistance;
    final end = i + matchDistance + 1 > len2 ? len2 : i + matchDistance + 1;
    for (var j = start; j < end; j++) {
      if (s2Matches[j] || s1[i] != s2[j]) continue;
      s1Matches[i] = true;
      s2Matches[j] = true;
      matches++;
      break;
    }
  }
  if (matches == 0) return 0.0;

  var transpositions = 0;
  var k = 0;
  for (var i = 0; i < len1; i++) {
    if (!s1Matches[i]) continue;
    while (!s2Matches[k]) {
      k++;
    }
    if (s1[i] != s2[k]) transpositions++;
    k++;
  }

  final m = matches.toDouble();
  return (m / len1 + m / len2 + (m - transpositions / 2) / m) / 3;
}

/// Jaro-Winkler similarity: Jaro plus a boost for a shared prefix (up to 4
/// characters), which is what makes "Transport" match "Transportation".
double jaroWinklerSimilarity(String s1, String s2) {
  final jaro = jaroSimilarity(s1, s2);
  if (jaro == 0.0) return 0.0;
  var prefix = 0;
  final maxPrefix = s1.length < s2.length ? s1.length : s2.length;
  while (prefix < maxPrefix && prefix < 4 && s1[prefix] == s2[prefix]) {
    prefix++;
  }
  return jaro + prefix * 0.1 * (1 - jaro);
}

/// Token-set similarity (0.0 – 1.0): Jaccard overlap of the two names'
/// tokens, with a high score when one name's tokens are a subset of the
/// other's ("Food" vs "Food & Dining").
double tokenSimilarity(String a, String b) {
  final tokensA = categoryTokens(a).toSet();
  final tokensB = categoryTokens(b).toSet();
  if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
  final intersection = tokensA.intersection(tokensB).length;
  if (intersection == 0) return 0.0;
  if (tokensA.length <= tokensB.length && tokensA.difference(tokensB).isEmpty) {
    return 0.9;
  }
  if (tokensB.length <= tokensA.length && tokensB.difference(tokensA).isEmpty) {
    return 0.9;
  }
  final union = tokensA.union(tokensB).length;
  return intersection / union;
}

/// Overall similarity between two category names (0.0 – 1.0). 1.0 means the
/// names are the same category after cleanup; anything at or above
/// [kCategorySimilarityThreshold] is treated as a duplicate.
double categorySimilarity(String a, String b) {
  final normalizedA = normalizeCategoryName(a);
  final normalizedB = normalizeCategoryName(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) return 0.0;
  if (normalizedA == normalizedB) return 1.0;
  final jaroWinkler = jaroWinklerSimilarity(normalizedA, normalizedB);
  final tokenScore = tokenSimilarity(a, b);
  return jaroWinkler > tokenScore ? jaroWinkler : tokenScore;
}

/// Groups of duplicate category names. Each group has 2+ names, in input
/// order; names that are not duplicates of anything are left out.
List<List<String>> findDuplicateGroups(
  List<String> names, {
  double threshold = kCategorySimilarityThreshold,
}) {
  final parent = List<int>.generate(names.length, (i) => i);

  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }

  void union(int a, int b) {
    parent[find(a)] = find(b);
  }

  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      if (categorySimilarity(names[i], names[j]) >= threshold) {
        union(i, j);
      }
    }
  }

  final groups = <int, List<String>>{};
  for (var i = 0; i < names.length; i++) {
    groups.putIfAbsent(find(i), () => []).add(names[i]);
  }
  return groups.values.where((group) => group.length > 1).toList();
}

/// The name a duplicate group should be merged into: the member with the
/// highest usage count (keyword count, expense count, ...), ties broken by
/// input order (earliest created wins).
String pickCanonical(
  List<String> group, {
  Map<String, int>? usageCounts,
}) {
  var best = group.first;
  var bestScore = usageCounts?[best] ?? 0;
  for (final name in group.skip(1)) {
    final score = usageCounts?[name] ?? 0;
    if (score > bestScore) {
      best = name;
      bestScore = score;
    }
  }
  return best;
}

/// The existing category most similar to [name], or null when nothing is
/// similar enough. Names that are identical after cleanup are NOT returned
/// here — that case is an exact duplicate, handled by the caller.
String? findBestMatch(
  String name,
  List<String> existing, {
  double threshold = kCategorySimilarityThreshold,
}) {
  final normalized = normalizeCategoryName(name);
  String? best;
  var bestScore = threshold;
  for (final candidate in existing) {
    if (normalizeCategoryName(candidate) == normalized) continue;
    final score = categorySimilarity(name, candidate);
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best;
}
