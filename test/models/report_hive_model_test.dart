import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/features/reports/data/models/report_hive_model.dart';

void main() {
  test('ReportHiveModel maps attachment aliases and supports copyWith', () {
    final model = ReportHiveModel.fromJson({
      'id': 'r1',
      'userId': 'u1',
      'createdAt': 123,
      'category': 'Overflow',
      'location': 'Ward 5',
      'message': 'Pile up',
      'status': 'pending',
      'attachment': '/uploads/report.jpg',
    });

    expect(model.attachmentUrl, '/uploads/report.jpg');

    final updated = model.copyWith(status: 'resolved', message: 'Cleared');
    expect(updated.status, 'resolved');
    expect(updated.message, 'Cleared');
    expect(updated.attachmentUrl, '/uploads/report.jpg');
  });
}
