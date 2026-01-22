class InvoiceModel {
  final String id;
  final String period;
  final double amountNPR;
  final String status;
  final DateTime issuedAt;
  final DateTime dueAt;

  const InvoiceModel({
    required this.id,
    required this.period,
    required this.amountNPR,
    required this.status,
    required this.issuedAt,
    required this.dueAt,
  });

  bool get isPaid => status.toLowerCase() == 'paid';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final id = _stringValue(json['id']) ?? _stringValue(json['_id']) ?? '';
    final period = _stringValue(json['period']) ?? 'Billing period';
    final status = _stringValue(json['status']) ?? 'Due';
    final amount = _numValue(json['amountNPR']) ?? 0;
    final issuedAt = _parseDate(json['issuedAt']) ?? DateTime.now();
    final dueAt = _parseDate(json['dueAt']) ?? issuedAt;

    return InvoiceModel(
      id: id,
      period: period,
      amountNPR: amount.toDouble(),
      status: status,
      issuedAt: issuedAt,
      dueAt: dueAt,
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? period,
    double? amountNPR,
    String? status,
    DateTime? issuedAt,
    DateTime? dueAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      period: period ?? this.period,
      amountNPR: amountNPR ?? this.amountNPR,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: dueAt ?? this.dueAt,
    );
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final cleaned = value.toString().trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static num? _numValue(dynamic value) {
    if (value is num) return value;
    if (value == null) return null;
    return num.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
