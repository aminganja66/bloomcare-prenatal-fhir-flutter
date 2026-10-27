import 'package:bloomcare/core/config/api_endpoints.dart';
import 'package:bloomcare/core/error/exceptions.dart';
import 'package:bloomcare/core/network/fhir_probe.dart';
import 'package:bloomcare/core/storage/token_store.dart';
import 'package:bloomcare/core/utils/safe_logger.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// SMART on FHIR standalone launch (authorization code + PKCE).
class SmartAuthService {
  SmartAuthService({FlutterAppAuth? appAuth, FhirProbe? probe, TokenStore? store})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _probe = probe ?? FhirProbe(),
        _store = store ?? TokenStore();

  final FlutterAppAuth _appAuth;
  final FhirProbe _probe;
  final TokenStore _store;

  Future<AuthSession> connect() async {
    final endpoints = await _probe.fetchSmartEndpoints();
    final auth = endpoints.authorization;
    final token = endpoints.token;
    if (auth == null || token == null) {
      throw StateError('SMART configuration is missing OAuth endpoints');
    }

    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AuthConfig.clientId,
        AuthConfig.redirectUrl,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: auth,
          tokenEndpoint: token,
        ),
        scopes: AuthConfig.scopes,
        additionalParameters: {'aud': ApiEndpoints.fhirBase},
      ),
    );

    final accessToken = result.accessToken;
    if (accessToken == null) throw StateError('No access token returned');

    final session = AuthSession(
      accessToken: accessToken,
      refreshToken: result.refreshToken,
      patientId: result.tokenAdditionalParameters?['patient']?.toString(),
      expiresAt: result.accessTokenExpirationDateTime,
    );
    await _store.save(session);
    SafeLogger.debug('Connected, patient id: ${session.patientId}');
    return session;
  }

  /// Exchanges the stored refresh token for a new access token.
  /// Throws [AuthException] if there is no refresh token or the server rejects it.
  Future<AuthSession> refresh() async {
    final current = await _store.read();
    final refreshToken = current?.refreshToken;
    if (refreshToken == null) throw const AuthException('No refresh token');

    final endpoints = await _probe.fetchSmartEndpoints();
    final auth = endpoints.authorization;
    final token = endpoints.token;
    if (auth == null || token == null) {
      throw const AuthException('SMART configuration is missing OAuth endpoints');
    }

    try {
      final result = await _appAuth.token(
        TokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: auth,
            tokenEndpoint: token,
          ),
          refreshToken: refreshToken,
          scopes: AuthConfig.scopes,
        ),
      );
      final accessToken = result.accessToken;
      if (accessToken == null) throw const AuthException('No access token returned');

      final session = AuthSession(
        accessToken: accessToken,
        refreshToken: result.refreshToken ?? refreshToken,
        patientId: result.tokenAdditionalParameters?['patient']?.toString() ??
            current?.patientId,
        expiresAt: result.accessTokenExpirationDateTime,
      );
      await _store.save(session);
      return session;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Token refresh failed: $e');
    }
  }

  Future<AuthSession?> restore() => _store.read();

  Future<void> disconnect() => _store.clear();
}
