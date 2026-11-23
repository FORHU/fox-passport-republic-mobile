import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';

class SpecialtySuggestionState {
  const SpecialtySuggestionState({
    this.sending = false,
    this.sent,
    this.error,
  });

  final bool sending;

  /// The name last sent for review, shown as a confirmation.
  final String? sent;

  /// What the API said when it refused, or '' for an unknown failure.
  final String? error;
}

/// A Provider applicant asking for a specialty the catalog lacks (api#440).
/// The request goes to review; it never joins the applicant's picks.
class SpecialtySuggestionController extends Notifier<SpecialtySuggestionState> {
  @override
  SpecialtySuggestionState build() => const SpecialtySuggestionState();

  /// Sends [name]. Returns whether the API took it.
  Future<bool> suggest(String name) async {
    final clean = name.trim();
    if (state.sending || clean.length < 2) return false;
    state = const SpecialtySuggestionState(sending: true);
    try {
      await ref.read(providerSpecialtiesRepositoryProvider).suggest(clean);
      if (!ref.mounted) return true;
      state = SpecialtySuggestionState(sent: clean);
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = SpecialtySuggestionState(
        error: e is AppException ? e.message : '',
      );
      return false;
    }
  }
}

final NotifierProvider<SpecialtySuggestionController, SpecialtySuggestionState>
    specialtySuggestionControllerProvider = NotifierProvider.autoDispose<
        SpecialtySuggestionController, SpecialtySuggestionState>(
  SpecialtySuggestionController.new,
);
