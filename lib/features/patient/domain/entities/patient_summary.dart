import 'package:equatable/equatable.dart';
import 'package:fhir_r4/fhir_r4.dart';

class PatientSummary extends Equatable {
  const PatientSummary({
    required this.id,
    this.name,
    this.birthDate,
    this.gender,
    this.phone,
  });

  final String id;
  final String? name;
  final String? birthDate;
  final String? gender;
  final String? phone;

  factory PatientSummary.fromPatient(Patient p) {
    final n = p.name?.firstOrNull;
    final given = n?.given?.map((g) => g.valueString).whereType<String>() ?? [];
    final fullName = [...given, if (n?.family?.valueString != null) n!.family!.valueString!]
        .join(' ');
    final phone = p.telecom
        ?.where((t) => t.system == ContactPointSystem.phone)
        .firstOrNull
        ?.value
        ?.valueString;
    return PatientSummary(
      id: p.id?.valueString ?? '',
      name: fullName.isEmpty ? null : fullName,
      birthDate: p.birthDate?.valueString,
      gender: p.gender?.valueString,
      phone: phone,
    );
  }

  @override
  List<Object?> get props => [id, name, birthDate, gender, phone];
}
