String? resolveMediaUrl(String baseUrl, String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final baseUri = Uri.tryParse(baseUrl);
  if (baseUri == null || baseUri.host.isEmpty) {
    final cleanBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = value.startsWith('/') ? value : '/$value';
    return '$cleanBase$cleanPath';
  }

  // Keep only scheme/host/port for media URLs so `/api/v1` is not duplicated.
  final origin = Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
  ).toString();

  final cleanOrigin =
      origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
  final cleanPath = value.startsWith('/') ? value : '/$value';
  return '$cleanOrigin$cleanPath';
}
