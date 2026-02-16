import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/features/payments/data/models/invoice_model.dart';

void main() {
  group('InvoiceModel', () {
    test('fromJson maps canonical fields', () {
      final model = InvoiceModel.fromJson({
        'id': 'inv_1',
        'period': 'Jan 2025',
        'amountNPR': 1200,
        'status': 'Due',
        'issuedAt': '2025-01-01T00:00:00.000Z',
        'dueAt': '2025-01-15T00:00:00.000Z',
      });

      expect(model.id, 'inv_1');
      expect(model.period, 'Jan 2025');
      expect(model.amountNPR, 1200);
      expect(model.status, 'Due');
    });

    test('fromJson supports _id fallback and trims values', () {
      final model = InvoiceModel.fromJson({
        '_id': ' inv_2 ',
        'period': ' Feb 2025 ',
        'amountNPR': '1500.50',
      });

      expect(model.id, 'inv_2');
      expect(model.period, 'Feb 2025');
      expect(model.amountNPR, 1500.50);
    });

    test('fromJson falls back to safe defaults', () {
      final model = InvoiceModel.fromJson({});

      expect(model.id, '');
      expect(model.period, 'Billing period');
      expect(model.status, 'Due');
      expect(model.amountNPR, 0);
    });

    test('isPaid is true for paid status irrespective of case', () {
      final model = InvoiceModel.fromJson({
        'id': 'inv_3',
        'status': 'PAID',
      });

      expect(model.isPaid, isTrue);
    });

    test('copyWith updates only changed fields', () {
      final original = InvoiceModel.fromJson({
        'id': 'inv_4',
        'status': 'Due',
      });

      final updated = original.copyWith(status: 'Paid');

      expect(updated.id, 'inv_4');
      expect(updated.status, 'Paid');
      expect(updated.period, original.period);
    });
  });
}
