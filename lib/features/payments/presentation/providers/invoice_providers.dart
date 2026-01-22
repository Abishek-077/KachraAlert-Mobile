import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository_api.dart';
import '../../domain/repositories/invoice_repository.dart';

final invoiceRepoProvider = Provider<InvoiceRepository>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return InvoiceRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final invoicesProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<InvoiceModel>>>(
  (ref) => InvoicesNotifier(ref.watch(invoiceRepoProvider)),
);

class InvoicesNotifier extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  InvoicesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final InvoiceRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repo.fetchInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<InvoiceModel> payInvoice(String invoiceId) async {
    final updated = await _repo.payInvoice(invoiceId);

    state = state.whenData((invoices) {
      final index = invoices.indexWhere((item) => item.id == invoiceId);
      if (index == -1) return invoices;
      final copy = [...invoices];
      copy[index] = updated;
      return copy;
    });

    return updated;
  }
}
