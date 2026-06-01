import 'dart:async';
import 'package:flutter/foundation.dart';

extension SafeStreamFirst<T> on Stream<T> {
  /// Safely gets the first element emitted by the stream.
  /// If the stream closes empty or throws an error, it returns the [defaultValue].
  Future<T> firstOrDefault(T defaultValue) async {
    try {
      return await first;
    } catch (e) {
      debugPrint('SafeStreamFirst: stream closed or errored, returning default. Error: $e');
      return defaultValue;
    }
  }
}
