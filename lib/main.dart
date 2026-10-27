import 'package:bloomcare/features/patient/data/repositories/fhir_repository.dart';
import 'package:bloomcare/core/network/smart_auth_service.dart';
import 'package:bloomcare/features/patient/presentation/pages/patient_page.dart';
import 'package:bloomcare/core/storage/token_store.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomCare',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ConnectPage(),
    );
  }
}

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _auth = SmartAuthService();
  late final _repository = FhirRepository(auth: _auth);
  AuthSession? _session;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _auth.restore().then((s) {
      if (mounted) setState(() => _session = s);
    });
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await _auth.connect();
      if (mounted) setState(() => _session = s);
    } catch (e) {
      if (mounted) setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    await _auth.disconnect();
    if (mounted) setState(() => _session = null);
  }

  Future<void> _sessionExpired() async {
    await _auth.disconnect();
    if (mounted) {
      setState(() {
        _session = null;
        _error = 'Session expired, please connect again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(title: const Text('BloomCare')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              if (s == null)
                FilledButton(
                  onPressed: _busy ? null : _connect,
                  child: Text(_busy ? 'Connecting…' : 'Connect'),
                )
              else ...[
                const Text('Connected'),
                const SizedBox(height: 8),
                Text('Patient id: ${s.patientId ?? 'unknown'}'),
                const SizedBox(height: 16),
                if (s.patientId != null)
                  Expanded(
                    child: PatientPage(
                      patientId: s.patientId!,
                      repository: _repository,
                      onSessionExpired: _sessionExpired,
                    ),
                  ),
                OutlinedButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
