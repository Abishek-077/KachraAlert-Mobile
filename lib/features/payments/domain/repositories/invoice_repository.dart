import '../../data/models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceModel>> fetchInvoices();
  Future<InvoiceModel> payInvoice(String invoiceId);
}
