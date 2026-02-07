class AdminUser {
  final String id;
  final String accountType;
  final String name;
  final String email;
  final String phone;
  final String society;
  final String building;
  final String apartment;
  final bool isBanned;
  final double lateFeePercent;
  final String? profileImageUrl;

  const AdminUser({
    required this.id,
    required this.accountType,
    required this.name,
    required this.email,
    required this.phone,
    required this.society,
    required this.building,
    required this.apartment,
    required this.isBanned,
    required this.lateFeePercent,
    this.profileImageUrl,
  });

  bool get isAdmin => accountType == 'admin_driver';
  String get roleLabel => isAdmin ? 'Admin/Driver' : 'Resident';
  String get statusLabel => isBanned ? 'Banned' : 'Active';

  AdminUser copyWith({
    String? accountType,
    String? name,
    String? email,
    String? phone,
    String? society,
    String? building,
    String? apartment,
    bool? isBanned,
    double? lateFeePercent,
    String? profileImageUrl,
  }) {
    return AdminUser(
      id: id,
      accountType: accountType ?? this.accountType,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      society: society ?? this.society,
      building: building ?? this.building,
      apartment: apartment ?? this.apartment,
      isBanned: isBanned ?? this.isBanned,
      lateFeePercent: lateFeePercent ?? this.lateFeePercent,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final rawAccount = _stringValue(
      json['accountType'] ?? json['role'],
      fallback: 'resident',
    );
    final accountType = rawAccount == 'admin' ? 'admin_driver' : rawAccount;

    return AdminUser(
      id: _stringValue(json['id'] ?? json['_id']),
      accountType: accountType,
      name: _stringValue(json['name'] ?? json['fullName']),
      email: _stringValue(json['email']),
      phone: _stringValue(json['phone']),
      society: _stringValue(json['society']),
      building: _stringValue(json['building']),
      apartment: _stringValue(json['apartment']),
      isBanned: _boolValue(json['isBanned']),
      lateFeePercent: _doubleValue(json['lateFeePercent']),
      profileImageUrl: _nullableString(
        json['profileImageUrl'] ?? json['profilePhotoUrl'] ?? json['avatar'],
      ),
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'yes';
  }
  return false;
}

double _doubleValue(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return 0;
}
