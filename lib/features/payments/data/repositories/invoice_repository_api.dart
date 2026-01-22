import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/invoice_model.dart';
import '../../domain/repositories/invoice_repository.dart';

class InvoiceRepositoryApi implements InvoiceRepository {
  InvoiceRepositoryApi({required ApiClient client, required this.accessToken})
      : _client = client;

  final ApiClient _client;
  final String? accessToken;

  @override
  Future<List<InvoiceModel>> fetchInvoices() async {
    final response = await _client.getJson(
      ApiEndpoints.invoices,
      accessToken: accessToken,
    );
    final items = _extractList(response);
    return items.map(InvoiceModel.fromJson).toList();
  }

  @override
  Future<InvoiceModel> payInvoice(String invoiceId) async {
    final response = await _client.postJson(
      '${ApiEndpoints.invoices}/$invoiceId/pay',
      const <String, dynamic>{},
      accessToken: accessToken,
    );
    final payload = _extractItem(response);
    return InvoiceModel.fromJson(payload);
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data =
        response['data'] ?? response['invoices'] ?? response['items'] ?? response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['invoices'] ?? data['items'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _extractItem(Map<String, dynamic> response) {
    final data = response['data'] ?? response['invoice'] ?? response;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
