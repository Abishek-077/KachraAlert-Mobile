import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/utils/time_ago.dart';

void main() {
  group('timeAgo', () {
    test('formats minutes for recent timestamps', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final recent = now.subtract(const Duration(minutes: 12));
      expect(timeAgo(recent.millisecondsSinceEpoch, now: now), '12m ago');
    });

    test('formats hours for same-day timestamps', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final earlier = now.subtract(const Duration(hours: 5));
      expect(timeAgo(earlier.millisecondsSinceEpoch, now: now), '5h ago');
    });

    test('formats days for older timestamps', () {
      final now = DateTime(2024, 1, 10, 12, 0, 0);
      final earlier = now.subtract(const Duration(days: 3));
      expect(timeAgo(earlier.millisecondsSinceEpoch, now: now), '3d ago');
    });
  });
}
