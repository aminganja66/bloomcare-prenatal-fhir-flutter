import 'package:bloomcare/core/network/fhir_probe.dart';
import 'package:flutter_test/flutter_test.dart';

// Hits the live public sandbox.
void main() {
  final probe = FhirProbe();

  test('fetches first Patient without auth', () async {
    final patient = await probe.fetchFirstPatient();
    expect(patient, isNotNull);
  });

  test('reads SMART endpoints', () async {
    final e = await probe.fetchSmartEndpoints();
    expect(e.authorization, 'https://launch.smarthealthit.org/v/r4/auth/authorize');
    expect(e.token, 'https://launch.smarthealthit.org/v/r4/auth/token');
  });
}
