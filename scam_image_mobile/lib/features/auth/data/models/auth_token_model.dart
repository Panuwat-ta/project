import '../../domain/entities/auth_token.dart';

/// Data-layer model for [AuthToken].
///
/// Extends the domain entity and adds JSON serialisation helpers.
class AuthTokenModel extends AuthToken {
  const AuthTokenModel({
    required super.accessToken,
    required super.refreshToken,
    super.expiresAt,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) => AuthTokenModel(
        accessToken: json['accessToken'] as String? ??
            json['access_token'] as String,
        refreshToken: json['refreshToken'] as String? ??
            json['refresh_token'] as String,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt?.toIso8601String(),
      };
}
