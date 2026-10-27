import 'package:bloomcare/features/patient/data/repositories/fhir_repository.dart';
import 'package:bloomcare/features/patient/presentation/bloc/patient_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatientPage extends StatelessWidget {
  const PatientPage({
    super.key,
    required this.patientId,
    required this.repository,
    required this.onSessionExpired,
  });

  final String patientId;
  final FhirRepository repository;
  final VoidCallback onSessionExpired;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientBloc(repository)..add(PatientRequested(patientId)),
      child: BlocConsumer<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientUnauthenticated) onSessionExpired();
        },
        builder: (context, state) => switch (state) {
          PatientLoading() || PatientUnauthenticated() =>
            const Center(child: CircularProgressIndicator()),
          PatientError(:final message) => Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Text(message),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context
                        .read<PatientBloc>()
                        .add(PatientRequested(patientId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          PatientLoaded(:final patient) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Row('Name', patient.name),
                _Row('Birth date', patient.birthDate),
                _Row('Gender', patient.gender),
                _Row('Phone', patient.phone),
              ],
            ),
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label),
        subtitle: Text(value ?? '—'),
      );
}
