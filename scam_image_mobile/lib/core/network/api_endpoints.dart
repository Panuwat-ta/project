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
  static const String scans = '/scan/';

  /// GET/DELETE /scan/{taskId}
  static String scanById(String taskId) => '/scan/$taskId';

  /// GET /scan/{taskId} (The server returns the result directly on the scan endpoint)
  static String scanResult(String taskId) => '/scan/$taskId';

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
