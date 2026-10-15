import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/foxers/foxer_profile.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/widgets/booking_calendar.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// "Match me": tell a Foxer what you have in mind, for which day and how many
/// guests. They accept or decline; nothing is charged until they accept.
class MatchRequestPage extends ConsumerStatefulWidget {
  const MatchRequestPage({required this.item, super.key});

  final CatalogItem item;

  @override
  ConsumerState<MatchRequestPage> createState() => _MatchRequestPageState();
}

class _MatchRequestPageState extends ConsumerState<MatchRequestPage> {
  static const _ownIdea = '';

  final _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);
  final _message = TextEditingController();

  String _style = _ownIdea;
  DateTime? _date;
  int _guests = 2;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(FoxerProfile profile) async {
    final l10n = context.l10n;
    final date = _date;
    if (date == null || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(foxerRepositoryProvider).sendMatch(
            MatchRequest(
              foxerId: profile.id,
              date: date,
              guests: _guests,
              style: _style,
              message: _message.text,
            ),
            isSample: profile.isSample,
          );
      ref.invalidate(myMatchRequestsProvider);
      if (mounted) setState(() => _sent = true);
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.matchFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final async = ref.watch(foxerProfileProvider(widget.item));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.matchTitle, style: AppTypography.display()),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => Center(
          child: Text(
            l10n.foxerLoadFailed,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ),
        data: (profile) => _sent
            ? _Sent(
                name: profile.name,
                onViewRequests: () => context.go(RouteNames.ticketsRequests),
                onDone: () => context.go(RouteNames.home),
              )
            : _Form(
                profile: profile,
                locale: locale,
                today: _today,
                month: _month,
                date: _date,
                guests: _guests,
                style: _style,
                message: _message,
                sending: _sending,
                onMonth: (m) => setState(() => _month = m),
                onDate: (d) => setState(() => _date = d),
                onGuests: (n) => setState(() => _guests = n),
                onStyle: (s) => setState(() => _style = s),
                onSend: () => _send(profile),
              ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.profile,
    required this.locale,
    required this.today,
    required this.month,
    required this.date,
    required this.guests,
    required this.style,
    required this.message,
    required this.sending,
    required this.onMonth,
    required this.onDate,
    required this.onGuests,
    required this.onStyle,
    required this.onSend,
  });

  final FoxerProfile profile;
  final String locale;
  final DateTime today;
  final DateTime month;
  final DateTime? date;
  final int guests;
  final String style;
  final TextEditingController message;
  final bool sending;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<int> onGuests;
  final ValueChanged<String> onStyle;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = [for (final o in profile.offers) o.title];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                l10n.matchIntro(profile.name),
                style: AppTypography.body(),
              ),
              const SizedBox(height: 20),
              _Label(l10n.matchWhat),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in styles)
                    _Choice(
                      label: s,
                      selected: style == s,
                      onTap: () => onStyle(s),
                    ),
                  _Choice(
                    label: l10n.matchOwnIdea,
                    selected: style.isEmpty,
                    onTap: () => onStyle(''),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Label(l10n.matchWhen),
              BookingCalendar(
                month: month,
                today: today,
                selected: date,
                unavailable: const {},
                onSelect: onDate,
                onMonthChanged: onMonth,
              ),
              const SizedBox(height: 24),
              _Label(l10n.matchGuests),
              Row(
                children: [
                  _Step(
                    icon: Icons.remove_rounded,
                    onTap: guests > 1 ? () => onGuests(guests - 1) : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$guests',
                        style: AppTypography.display(size: 26),
                      ),
                    ),
                  ),
                  _Step(
                    icon: Icons.add_rounded,
                    onTap: () => onGuests(guests + 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Label(l10n.matchMessage),
              TextField(
                controller: message,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                cursorColor: AppColors.accent,
                style: AppTypography.body(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.matchMessageHint,
                  hintStyle: AppTypography.body(color: AppColors.textMuted),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.matchNoCharge, style: AppTypography.body(size: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? l10n.bookPickDate
                        : DateFormat('EEE d MMM', locale).format(date!),
                    style: AppTypography.display(),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: date == null || sending ? null : onSend,
                    style: ElevatedButton.styleFrom(
                      // The theme makes buttons full width, which a Row
                      // cannot hold.
                      minimumSize: const Size(150, 52),
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      disabledBackgroundColor:
                          AppColors.accent.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onAccent,
                            ),
                          )
                        : Text(
                            l10n.matchSend,
                            style: AppTypography.display(
                              color: AppColors.onAccent,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Sent extends StatelessWidget {
  const _Sent({
    required this.name,
    required this.onViewRequests,
    required this.onDone,
  });

  final String name;
  final VoidCallback onViewRequests;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 34,
              color: AppColors.onAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.matchSentTitle,
            style: AppTypography.display(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.matchSentBody(name),
            style: AppTypography.body(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onViewRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
              ),
              child: Text(
                l10n.matchViewRequests,
                style: AppTypography.display(color: AppColors.onAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
              ),
              child: Text(l10n.bookBackHome),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppTypography.display()),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentTintBg : Colors.transparent,
            borderRadius: AppRadius.brPill,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderStrong,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body(
              size: 13,
              color: selected ? AppColors.accent : AppColors.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape:
          const CircleBorder(side: BorderSide(color: AppColors.borderStrong)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onTap == null ? AppColors.textFaint : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
