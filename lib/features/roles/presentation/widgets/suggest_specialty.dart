import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/presentation/controllers/specialty_suggestion_controller.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Asks for a category the list lacks (api#440). It goes to review and is
/// not added to the applicant's picks: they apply with what is listed now.
class SuggestSpecialty extends ConsumerStatefulWidget {
  const SuggestSpecialty({super.key});

  @override
  ConsumerState<SuggestSpecialty> createState() => _SuggestSpecialtyState();
}

class _SuggestSpecialtyState extends ConsumerState<SuggestSpecialty> {
  final _name = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await ref
        .read(specialtySuggestionControllerProvider.notifier)
        .suggest(_name.text);
    if (!mounted || !sent) return;
    _name.clear();
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(specialtySuggestionControllerProvider);
    final sent = state.sent;
    final error = state.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sent != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.roleApplySuggestSpecialtySent(sent),
                    style: AppTypography.body(size: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!_open)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.roleApplySuggestLead,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
              TextButton(
                onPressed: () => setState(() => _open = true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  textStyle: AppTypography.body(size: 13).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: Text(l10n.roleApplySuggestSpecialtyPrompt),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.roleApplySuggestSpecialtyLabel,
                        style: AppTypography.body(size: 13),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.roleApplySuggestClose,
                      onPressed: () => setState(() => _open = false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('suggest-specialty-name'),
                        controller: _name,
                        maxLength: 60,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.roleApplySuggestHint,
                          counterText: '',
                          errorText: error == null
                              ? null
                              : error.isEmpty
                                  ? l10n.roleApplySuggestSpecialtyFailed
                                  : error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.roleApplySuggestHelp,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _name,
                        builder: (context, value, _) => SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed:
                                value.text.trim().length >= 2 && !state.sending
                                    ? _send
                                    : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: AppColors.textPrimary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            child: state.sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.roleApplySuggestSpecialtySend,
                                    style: AppTypography.display(size: 15),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
