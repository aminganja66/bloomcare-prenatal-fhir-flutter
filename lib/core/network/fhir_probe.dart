import 'dart:convert';

import 'package:bloomcare/core/config/api_endpoints.dart';
import 'package:bloomcare/core/utils/safe_logger.dart';
import 'package:fhir_r4/fhir_r4.dart';
import 'package:http/http.dart' as http;

/// Unauthenticated sandbox checks: first Patient and SMART configuration.
class FhirProbe {
  FhirProbe({http.Client? client, this.fhirBase = ApiEndpoints.fhirBase})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String fhirBase;

  /// Returns null if the server rejects unauthenticated access.
  Future<Patient?> fetchFirstPatient() async {
    final res = await _client.get(
      Uri.parse('$fhirBase/Patient?_count=1'),
      headers: {'Accept': 'application/fhir+json'},
    );
    if (res.statusCode == 401 || res.statusCode == 403) {
      SafeLogger.debug('Patient search needs auth (${res.statusCode})');
      return null;
    }
    if (res.statusCode != 200) {
      throw http.ClientException('Patient search failed: ${res.statusCode}');
    }
    final bundle = Bundle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    final patient = bundle.entry?.firstOrNull?.resource;
    if (patient is! Patient) return null;
    final name = patient.name?.firstOrNull;
    final given = name?.given?.map((g) => g.valueString).join(' ') ?? '';
    SafeLogger.debug('Patient name: $given ${name?.family?.valueString ?? ''}');
    return patient;
  }

  /// Returns (authorization_endpoint, token_endpoint).
  Future<({String? authorization, String? token})> fetchSmartEndpoints() async {
    final res = await _client.get(
      Uri.parse('$fhirBase/.well-known/smart-configuration'),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw http.ClientException('smart-configuration failed: ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final endpoints = (
      authorization: json['authorization_endpoint'] as String?,
      token: json['token_endpoint'] as String?,
    );
    SafeLogger.debug('authorization_endpoint: ${endpoints.authorization}');
    SafeLogger.debug('token_endpoint: ${endpoints.token}');
    return endpoints;
  }
}
