import 'dart:convert';

import 'package:bloomcare/core/config/api_endpoints.dart';
import 'package:bloomcare/core/error/exceptions.dart';
import 'package:bloomcare/core/network/smart_auth_service.dart';
import 'package:bloomcare/features/patient/domain/entities/patient_summary.dart';
import 'package:fhir_r4/fhir_r4.dart';
import 'package:http/http.dart' as http;

class FhirRepository {
  FhirRepository({
    required SmartAuthService auth,
    http.Client? client,
    this.fhirBase = ApiEndpoints.fhirBase,
  })  : _auth = auth,
        _client = client ?? http.Client();

  final SmartAuthService _auth;
  final http.Client _client;
  final String fhirBase;

  /// On 401 the token is refreshed once and the request retried.
  /// Throws [AuthException] when the session can't be recovered (log in again).
  Future<PatientSummary> getPatient(String id) async {
    var session = await _auth.restore();
    if (session == null) throw const AuthException('Not signed in');

    var res = await _get(id, session.accessToken);
    if (res.statusCode == 401) {
      session = await _auth.refresh();
      res = await _get(id, session.accessToken);
      if (res.statusCode == 401) {
        throw const AuthException('Session expired');
      }
    }
    if (res.statusCode != 200) {
      throw ServerException('Failed to load patient', statusCode: res.statusCode);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return PatientSummary.fromPatient(Patient.fromJson(json));
  }

  Future<http.Response> _get(String id, String token) => _client.get(
        Uri.parse('$fhirBase/Patient/$id'),
        headers: {
          'Accept': 'application/fhir+json',
          'Authorization': 'Bearer $token',
        },
      );
}
