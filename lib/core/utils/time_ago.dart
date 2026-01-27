String timeAgo(int millis, {DateTime? now}) {
  final nowMillis = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final diff = Duration(milliseconds: nowMillis - millis);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
