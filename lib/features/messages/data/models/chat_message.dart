class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['sender'] ?? '').toString(),
      recipientId: (json['recipientId'] ?? json['recipient'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      readAt: _parseDate(json['readAt']),
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
