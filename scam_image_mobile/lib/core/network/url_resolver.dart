/// Single URL-resolution truth for server file paths.
/// Pure function: the caller supplies baseUrl (no dotenv reads inside models).
/// Throws StateError when baseUrl is missing — same as the inline copies.
String? resolveUploadUrl(String? baseUrl, String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;

  if (baseUrl == null || baseUrl.trim().isEmpty) {
    throw StateError('API_BASE_URL is required and must be configured in .env');
  }
  final uri = Uri.parse(baseUrl.trim());
  final hostUrl = '${uri.scheme}://${uri.host}:${uri.port}';

  String cleanUrl = url.replaceAll(r'\', '/');
  if (cleanUrl.startsWith('./')) {
    cleanUrl = cleanUrl.substring(2);
  }
  if (!cleanUrl.startsWith('/')) {
    cleanUrl = '/$cleanUrl';
  }
  if (!cleanUrl.toLowerCase().startsWith('/uploads')) {
    cleanUrl = '/uploads$cleanUrl';
  }

  return '$hostUrl$cleanUrl';
}
