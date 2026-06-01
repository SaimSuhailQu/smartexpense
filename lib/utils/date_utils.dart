import 'package:flutter/material.dart';

enum TimeRange { daily, weekly, monthly, yearly, loans, categories, custom }


class DateUtils {
  static DateTimeRange getRangeDates(TimeRange range, DateTime date) {
    switch (range) {
      case TimeRange.daily:
        return DateTimeRange(
          start: DateTime(date.year, date.month, date.day),
          end: DateTime(date.year, date.month, date.day, 23, 59, 59),
        );
      case TimeRange.weekly:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(end.year, end.month, end.day, 23, 59, 59),
        );
      case TimeRange.monthly:
        return DateTimeRange(
          start: DateTime(date.year, date.month, 1),
          end: DateTime(date.year, date.month + 1, 0, 23, 59, 59),
        );
      case TimeRange.yearly:
        return DateTimeRange(
          start: DateTime(date.year, 1, 1),
          end: DateTime(date.year, 12, 31, 23, 59, 59),
        );
      case TimeRange.loans:
        // For loans, we don't need a specific date range
        // Return a default range that covers all time
        return DateTimeRange(
          start: DateTime(2000),
          end: DateTime(2100),
        );
      case TimeRange.categories:
        // For categories, we don't need a specific date range
        // Return a default range that covers all time
        return DateTimeRange(
          start: DateTime(2000),
          end: DateTime(2100),
        );
      case TimeRange.custom:
        return DateTimeRange(
          start: DateTime(date.year, date.month, date.day),
          end: DateTime(date.year, date.month, date.day, 23, 59, 59),
        );
    }

  }
}
