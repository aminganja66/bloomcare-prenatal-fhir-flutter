import 'dart:convert';

import 'package:bloomcare/core/error/exceptions.dart';
import 'package:bloomcare/core/network/smart_auth_service.dart';
import 'package:bloomcare/core/storage/token_store.dart';
import 'package:bloomcare/features/patient/data/repositories/fhir_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAuth extends SmartAuthService {
  _FakeAuth({this.refreshFails = false});
  final bool refreshFails;
  int refreshCalls = 0;

  @override
  Future<AuthSession?> restore() async => const AuthSession(accessToken: 'old');

  @override
  Future<AuthSession> refresh() async {
    refreshCalls++;
    if (refreshFails) throw const AuthException('nope');
    return const AuthSession(accessToken: 'new');
  }
}

final _patientJson = jsonEncode({
  'resourceType': 'Patient',
  'id': '42',
  'name': [
    {'family': 'Doe', 'given': ['Jane']},
  ],
  'gender': 'female',
  'birthDate': '1990-05-01',
  'telecom': [
    {'system': 'email', 'value': 'j@x.org'},
    {'system': 'phone', 'value': '555-1234'},
  ],
});

void main() {
  test('maps Patient to PatientSummary and sends bearer token', () async {
    String? header;
    final repo = FhirRepository(
      auth: _FakeAuth(),
      client: MockClient((req) async {
        header = req.headers['Authorization'];
        return http.Response(_patientJson, 200);
      }),
    );
    final p = await repo.getPatient('42');
    expect(header, 'Bearer old');
    expect(p.name, 'Jane Doe');
    expect(p.birthDate, '1990-05-01');
    expect(p.gender, 'female');
    expect(p.phone, '555-1234');
  });

  test('401 refreshes token and retries once', () async {
    final auth = _FakeAuth();
    final tokens = <String?>[];
    final repo = FhirRepository(
      auth: auth,
      client: MockClient((req) async {
        tokens.add(req.headers['Authorization']);
        return tokens.length == 1
            ? http.Response('', 401)
            : http.Response(_patientJson, 200);
      }),
    );
    await repo.getPatient('42');
    expect(tokens, ['Bearer old', 'Bearer new']);
    expect(auth.refreshCalls, 1);
  });

  test('401 with failed refresh throws AuthException', () async {
    final repo = FhirRepository(
      auth: _FakeAuth(refreshFails: true),
      client: MockClient((_) async => http.Response('', 401)),
    );
    expect(repo.getPatient('42'), throwsA(isA<AuthException>()));
  });
}
