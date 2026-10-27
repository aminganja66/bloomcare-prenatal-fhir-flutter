import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.patientId,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String? patientId;
  final DateTime? expiresAt;
}

/// Persists SMART tokens in the platform keystore/keychain only.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _patient = 'patient_id';
  static const _expires = 'expires_at';

  Future<void> save(AuthSession s) async {
    await _storage.write(key: _access, value: s.accessToken);
    await _storage.write(key: _refresh, value: s.refreshToken);
    await _storage.write(key: _patient, value: s.patientId);
    await _storage.write(key: _expires, value: s.expiresAt?.toIso8601String());
  }

  Future<AuthSession?> read() async {
    final access = await _storage.read(key: _access);
    if (access == null) return null;
    final expires = await _storage.read(key: _expires);
    return AuthSession(
      accessToken: access,
      refreshToken: await _storage.read(key: _refresh),
      patientId: await _storage.read(key: _patient),
      expiresAt: expires == null ? null : DateTime.tryParse(expires),
    );
  }

  Future<void> clear() => _storage.deleteAll();
}
