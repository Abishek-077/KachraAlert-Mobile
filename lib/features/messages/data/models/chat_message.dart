class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.senderName,
    required this.recipientName,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.senderProfileImageUrl,
    this.recipientProfileImageUrl,
    this.editedAt,
    this.deletedAt,
    this.isDeleted = false,
    this.replyTo,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String senderName;
  final String recipientName;
  final String? senderProfileImageUrl;
  final String? recipientProfileImageUrl;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final bool isDeleted;
  final ChatReplyPreview? replyTo;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = _asMap(json['sender']);
    final recipient = _asMap(json['recipient']);
    final senderId = (json['senderId'] ??
            sender?['id'] ??
            sender?['_id'] ??
            json['sender'] ??
            '')
        .toString();
    final recipientId = (json['recipientId'] ??
            recipient?['id'] ??
            recipient?['_id'] ??
            json['recipient'] ??
            '')
        .toString();
    final senderName =
        (json['senderName'] ?? sender?['name'] ?? '').toString().trim();
    final recipientName =
        (json['recipientName'] ?? recipient?['name'] ?? '').toString().trim();
    final senderProfileImageUrl = _nullableString(
      json['senderProfileImageUrl'] ??
          json['senderProfilePhotoUrl'] ??
          sender?['profileImageUrl'] ??
          sender?['profilePhotoUrl'],
    );
    final recipientProfileImageUrl = _nullableString(
      json['recipientProfileImageUrl'] ??
          json['recipientProfilePhotoUrl'] ??
          recipient?['profileImageUrl'] ??
          recipient?['profilePhotoUrl'],
    );
    final deletedAt = _parseDate(json['deletedAt']);
    final isDeleted = json['isDeleted'] == true || deletedAt != null;
    final replyPreview = ChatReplyPreview.fromJson(json['replyTo']);

    return ChatMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      senderId: senderId,
      recipientId: recipientId,
      senderName: senderName.isEmpty ? 'Unknown user' : senderName,
      recipientName: recipientName.isEmpty ? 'Unknown user' : recipientName,
      senderProfileImageUrl: senderProfileImageUrl,
      recipientProfileImageUrl: recipientProfileImageUrl,
      body: (json['body'] ?? json['message'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      readAt: _parseDate(json['readAt']),
      editedAt: _parseDate(json['editedAt']),
      deletedAt: deletedAt,
      isDeleted: isDeleted,
      replyTo: replyPreview.isEmpty ? null : replyPreview,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final millis = int.tryParse(value);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }
}

class ChatReplyPreview {
  const ChatReplyPreview({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.body,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String body;

  factory ChatReplyPreview.fromJson(dynamic raw) {
    if (raw is! Map) return const ChatReplyPreview.empty();
    final json = raw.cast<String, dynamic>();
    return ChatReplyPreview(
      messageId: (json['messageId'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderName: (json['senderName'] ?? 'Unknown user').toString(),
      body: (json['body'] ?? '').toString(),
    );
  }

  const ChatReplyPreview.empty()
      : messageId = '',
        senderId = '',
        senderName = '',
        body = '';

  bool get isEmpty => messageId.trim().isEmpty && body.trim().isEmpty;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return null;
}

String? _nullableString(dynamic raw) {
  if (raw == null) return null;
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}
