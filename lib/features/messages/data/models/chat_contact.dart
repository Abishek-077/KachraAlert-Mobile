class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.accountType,
    this.profileImageUrl,
  });

  final String id;
  final String name;
  final String accountType;
  final String? profileImageUrl;

  bool get isAdmin => accountType == 'admin_driver' || accountType == 'admin';

  String get subtitle => isAdmin ? 'Admin' : 'Resident';

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    final id =
        (json['id'] ?? json['_id'] ?? json['userId'] ?? '').toString().trim();
    final name = (json['name'] ?? json['fullName'] ?? json['email'] ?? '')
        .toString()
        .trim();
    final type = (json['accountType'] ?? json['role'] ?? 'resident')
        .toString()
        .trim();
    final photo = (json['profileImageUrl'] ?? json['profilePhotoUrl'])
        ?.toString()
        .trim();
    return ChatContact(
      id: id,
      name: name.isEmpty ? 'Unknown User' : name,
      accountType: type.isEmpty ? 'resident' : type,
      profileImageUrl: (photo == null || photo.isEmpty) ? null : photo,
    );
  }
}
