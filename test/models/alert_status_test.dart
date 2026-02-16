import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/features/alerts/domain/entities/alert_status.dart';

void main() {
  group('AlertStatusX.label', () {
    test('pending returns Pending', () {
      expect(AlertStatus.pending.label, 'Pending');
    });

    test('assigned returns Assigned', () {
      expect(AlertStatus.assigned.label, 'Assigned');
    });

    test('collected returns Collected', () {
      expect(AlertStatus.collected.label, 'Collected');
    });

    test('rejected returns Rejected', () {
      expect(AlertStatus.rejected.label, 'Rejected');
    });

    test('all statuses have non-empty labels', () {
      for (final status in AlertStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });
  });
}
