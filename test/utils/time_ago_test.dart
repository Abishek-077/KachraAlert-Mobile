import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/utils/time_ago.dart';

void main() {
  group('timeAgo', () {
    test('formats same minute timestamps as 0m ago', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      expect(timeAgo(now.millisecondsSinceEpoch, now: now), '0m ago');
    });

    test('formats recent timestamps in minutes', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final recent = now.subtract(const Duration(minutes: 12));
      expect(timeAgo(recent.millisecondsSinceEpoch, now: now), '12m ago');
    });

    test('uses minutes at the 59 minute boundary', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final earlier = now.subtract(const Duration(minutes: 59));
      expect(timeAgo(earlier.millisecondsSinceEpoch, now: now), '59m ago');
    });

    test('uses hours at the 60 minute boundary', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final earlier = now.subtract(const Duration(minutes: 60));
      expect(timeAgo(earlier.millisecondsSinceEpoch, now: now), '1h ago');
    });

    test('formats older timestamps in days', () {
      final now = DateTime(2024, 1, 10, 12, 0, 0);
      final earlier = now.subtract(const Duration(days: 3));
      expect(timeAgo(earlier.millisecondsSinceEpoch, now: now), '3d ago');
    });
  });
}
