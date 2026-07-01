import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for the onboarding consent checkboxes.
class ConsentState extends Equatable {
  const ConsentState({
    this.termsAccepted = false,
    this.researchConsent = false,
  });

  /// Whether the user has accepted the mandatory terms of service.
  final bool termsAccepted;

  /// Whether the user has opted in to research data usage (optional).
  final bool researchConsent;

  /// The "proceed" button is only enabled when [termsAccepted] is true.
  bool get canProceed => termsAccepted;

  ConsentState copyWith({bool? termsAccepted, bool? researchConsent}) {
    return ConsentState(
      termsAccepted: termsAccepted ?? this.termsAccepted,
      researchConsent: researchConsent ?? this.researchConsent,
    );
  }

  @override
  List<Object?> get props => [termsAccepted, researchConsent];
}

/// Manages the two consent toggles on the Onboarding screen.
class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit() : super(const ConsentState());

  /// Toggles the mandatory terms-of-service checkbox.
  void toggleTerms() =>
      emit(state.copyWith(termsAccepted: !state.termsAccepted));

  /// Toggles the optional research-consent checkbox.
  void toggleResearch() =>
      emit(state.copyWith(researchConsent: !state.researchConsent));
}
