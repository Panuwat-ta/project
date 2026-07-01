/// ApiEndpoints — centralised list of all REST API paths.
///
/// Use these constants everywhere instead of hard-coding endpoint strings.
/// Parameterised paths use static methods so the caller supplies the ID.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Authentication ────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ── Scans ─────────────────────────────────────────────────────────────────
  static const String scans = '/scans';

  /// GET/DELETE /scans/{taskId}
  static String scanById(String taskId) => '/scans/$taskId';

  /// GET /scans/{taskId}/result
  static String scanResult(String taskId) => '/scans/$taskId/result';

  // ── History ───────────────────────────────────────────────────────────────
  static const String history = '/history';

  /// GET/DELETE /history/{scanId}
  static String historyById(String scanId) => '/history/$scanId';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reports = '/reports';
  static const String reportCategories = '/reports/categories';

  // ── Consents / Privacy ────────────────────────────────────────────────────
  static const String consentsMe = '/consents/me';
  static const String privacyExport = '/privacy/export';
  static const String privacyDeleteAccount = '/privacy/account';
}
