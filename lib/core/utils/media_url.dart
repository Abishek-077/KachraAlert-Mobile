String? resolveMediaUrl(String baseUrl, String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final cleanPath = value.startsWith('/') ? value : '/$value';
  return '$cleanBase$cleanPath';
}
