import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../../data/models/invoice_model.dart';
import '../providers/invoice_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final Set<String> _payingInvoices = {};
  String _selectedProvider = 'khalti';

  static const _paymentOptions = <_PaymentOption>[
    _PaymentOption(
      key: 'khalti',
      label: 'Khalti',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF6A3DF3),
    ),
    _PaymentOption(
      key: 'esewa',
      label: 'eSewa',
      icon: Icons.qr_code_2_rounded,
      color: Color(0xFF21B46A),
    ),
    _PaymentOption(
      key: 'cash',
      label: 'Cash',
      icon: Icons.payments_outlined,
      color: Color(0xFFE58B1B),
    ),
    _PaymentOption(
      key: 'test',
      label: 'Test',
      icon: Icons.science_outlined,
      color: Color(0xFF0E6E66),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final cs = Theme.of(context).colorScheme;

    return MotionScaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.read(invoicesProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh invoices',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(invoicesProvider.notifier).load(),
        child: invoicesAsync.when(
          loading: () => _LoadingState(cs: cs),
          error: (err, _) => _ErrorState(
            message: err.toString(),
            onRetry: () => ref.read(invoicesProvider.notifier).load(),
          ),
          data: (invoices) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _BalanceSummaryCard(invoices: invoices),
              const SizedBox(height: 16),
              _PaymentMethodsCard(
                options: _paymentOptions,
                selected: _selectedProvider,
                onSelected: (value) =>
                    setState(() => _selectedProvider = value),
              ),
              const SizedBox(height: 18),
              Text(
                'INVOICES',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              if (invoices.isEmpty)
                _EmptyInvoicesCard(
                    onRefresh: () => ref.read(invoicesProvider.notifier).load())
              else
                ...invoices.map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InvoiceCard(
                      invoice: invoice,
                      provider: _selectedProvider,
                      isPaying: _payingInvoices.contains(invoice.id),
                      onPay: invoice.isPaid
                          ? null
                          : () => _confirmPayment(context, invoice),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPayment(
      BuildContext context, InvoiceModel invoice) async {
    final option = _paymentOptions.firstWhere(
      (element) => element.key == _selectedProvider,
      orElse: () => _paymentOptions.first,
    );

    final shouldPay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Text(
          'Pay NPR ${invoice.amountNPR.toStringAsFixed(0)} for ${invoice.period} using ${option.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (shouldPay != true) return;

    setState(() => _payingInvoices.add(invoice.id));
    try {
      await ref.read(invoicesProvider.notifier).payInvoice(invoice.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful for ${invoice.period}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _payingInvoices.remove(invoice.id));
      }
    }
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({required this.invoices});

  final List<InvoiceModel> invoices;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unpaid = invoices.where((invoice) => !invoice.isPaid).toList();
    final outstanding = unpaid.fold<double>(
      0,
      (total, invoice) => total + invoice.amountNPR,
    );
    final nextDue = unpaid.isEmpty
        ? null
        : (unpaid..sort((a, b) => a.dueAt.compareTo(b.dueAt))).first;

    return KCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUTSTANDING BALANCE',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NPR ${outstanding.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_available_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextDue == null
                      ? 'All invoices are paid.'
                      : 'Next due ${_formatDate(nextDue.dueAt)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              unpaid.isEmpty
                  ? 'No payments due'
                  : '${unpaid.length} invoice${unpaid.length == 1 ? '' : 's'} pending',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_PaymentOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT METHODS',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options
                .map(
                  (option) => _PaymentMethodChip(
                    option: option,
                    isSelected: option.key == selected,
                    onTap: () => onSelected(option.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final selectedOption = options.firstWhere(
                (option) => option.key == selected,
                orElse: () => options.first,
              );
              return Text(
                'Selected for checkout: ${selectedOption.label}',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.65),
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? option.color.withOpacity(0.12) : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? option.color : cs.outline.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, color: option.color, size: 18),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? option.color : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.provider,
    required this.isPaying,
    required this.onPay,
  });

  final InvoiceModel invoice;
  final String provider;
  final bool isPaying;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(invoice.status, cs);

    return KCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice.period,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              _StatusPill(label: invoice.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoItem(label: 'Issued', value: _formatDate(invoice.issuedAt)),
              const SizedBox(width: 16),
              _InfoItem(label: 'Due', value: _formatDate(invoice.dueAt)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'NPR ${invoice.amountNPR.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const Spacer(),
              if (invoice.isPaid)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ECA92).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1ECA92),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: isPaying ? null : onPay,
                    icon: isPaying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.credit_card_rounded, size: 18),
                    label: Text(isPaying
                        ? 'Processing'
                        : 'Pay with ${_titleCase(provider)}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyInvoicesCard extends StatelessWidget {
  const _EmptyInvoicesCard({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return KCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 40),
          const SizedBox(height: 12),
          const Text(
            'No invoices yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Once invoices are generated for your account, they will show here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 120),
      children: [
        Center(
          child: Column(
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading invoices...'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        KCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 180,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 220,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 120),
      children: [
        KCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline,
                  size: 44, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                'Unable to load invoices',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

Color _statusColor(String status, ColorScheme cs) {
  final normalized = status.toLowerCase();
  if (normalized == 'paid' || normalized == 'success') {
    return const Color(0xFF1ECA92);
  }
  if (normalized == 'overdue' || normalized == 'failed') {
    return cs.error;
  }
  return const Color(0xFFE58B1B);
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  return '$day $month ${date.year}';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}
