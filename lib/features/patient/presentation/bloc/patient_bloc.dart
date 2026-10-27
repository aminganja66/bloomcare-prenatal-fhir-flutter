import 'package:bloomcare/core/error/exceptions.dart';
import 'package:bloomcare/features/patient/data/repositories/fhir_repository.dart';
import 'package:bloomcare/features/patient/domain/entities/patient_summary.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PatientEvent extends Equatable {
  const PatientEvent();
  @override
  List<Object?> get props => [];
}

class PatientRequested extends PatientEvent {
  const PatientRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

sealed class PatientState extends Equatable {
  const PatientState();
  @override
  List<Object?> get props => [];
}

class PatientLoading extends PatientState {
  const PatientLoading();
}

class PatientLoaded extends PatientState {
  const PatientLoaded(this.patient);
  final PatientSummary patient;
  @override
  List<Object?> get props => [patient];
}

class PatientError extends PatientState {
  const PatientError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// Token refresh failed: the user must sign in again.
class PatientUnauthenticated extends PatientState {
  const PatientUnauthenticated();
}

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  PatientBloc(this._repository) : super(const PatientLoading()) {
    on<PatientRequested>((event, emit) async {
      emit(const PatientLoading());
      try {
        emit(PatientLoaded(await _repository.getPatient(event.id)));
      } on AuthException {
        emit(const PatientUnauthenticated());
      } on ServerException catch (e) {
        emit(PatientError('${e.message} (${e.statusCode})'));
      } catch (e) {
        emit(PatientError('Something went wrong: $e'));
      }
    });
  }

  final FhirRepository _repository;
}
