import 'package:cloud_firestore/cloud_firestore.dart';

/// Parses a Firestore date field from the shapes seen in the wild:
/// [Timestamp], int (millis since epoch), or ISO-8601 [String].
///
/// Throws [FormatException] on anything else. Callers (the stream mappers in
/// the services) catch per-document and skip the bad doc. That is deliberate:
/// the old code fell back to `DateTime.now()`, silently re-dating corrupt
/// rows to *today* and polluting the current month's reports.
DateTime parseModelDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Unparseable date value: $value');
}
