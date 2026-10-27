class ApiEndpoints {
  static const baseUrl= "https://launch.smarthealthit.org/?launch=WzMsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDAsMSwiIl0&fhir_version=r4";
  static const fhirBase = "https://launch.smarthealthit.org/v/r4/fhir";
}

class AuthConfig {
  static const clientId = 'bloomcare-demo';
  static const redirectUrl = 'com.bloomcare:/callback';
  static const scopes = [
    'openid',
    'fhirUser',
    'launch/patient',
    'patient/Patient.read',
    'patient/Observation.read',
    'patient/MedicationRequest.read',
    'offline_access',
  ];
}
