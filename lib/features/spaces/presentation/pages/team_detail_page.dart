import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// The team of one venue or event: who is on it, who is invited or asking, and
/// how to add Organizers and Check-in Helpers. Only the owner sees this.
class TeamDetailPage extends ConsumerStatefulWidget {
  const TeamDetailPage({required this.target, super.key});

  final TeamTarget target;

  @override
  ConsumerState<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends ConsumerState<TeamDetailPage> {
  final _input = TextEditingController();
  Timer? _debounce;
  TeamKind _kind = TeamKind.organizer;

  /// What the Organizer search is looking for; follows the field after a pause.
  String _query = '';
  bool _busy = false;
  bool _showPast = false;

  TeamTarget get _target => widget.target;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _typed(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  /// Runs one change, then reloads the team. The server's own words are shown
  /// when it refuses (an unknown email, someone already on the team).
  Future<void> _run(
    Future<void> Function() action,
    String success, {
    bool clearInput = false,
  }) async {
    final failed = context.l10n.teamActionFailed;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(teamProvider(_target));
      if (clearInput) {
        _input.clear();
        _query = '';
      }
      if (mounted) showTopToast(context, success);
    } on AppException catch (e) {
      if (mounted) {
        showTopToast(context, e.message.isEmpty ? failed : e.message);
      }
    } on Object {
      if (mounted) showTopToast(context, failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.messageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return sure ?? false;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final email = _input.text.trim();
    if (!email.contains('@')) return;
    final kind = _kind;
    await _run(
      () => ref
          .read(spacesRepositoryProvider)
          .appoint(_target, kind, email: email),
      kind == TeamKind.organizer ? l10n.teamInvited : l10n.teamHelperAdded,
      clearInput: true,
    );
  }

  Future<void> _inviteFound(OrganizerCard card) => _run(
        () => ref
            .read(spacesRepositoryProvider)
            .appoint(_target, TeamKind.organizer, userId: card.id),
        context.l10n.teamInvited,
        clearInput: true,
      );

  Future<void> _remove(TeamMember member, {required bool withdraw}) async {
    final l10n = context.l10n;
    final sure = await _confirm(
      withdraw
          ? l10n.teamWithdrawTitle(member.title)
          : l10n.teamRemoveTitle(member.title),
      withdraw ? l10n.teamWithdrawBody : l10n.teamRemoveBody,
      withdraw ? l10n.teamWithdraw : l10n.teamRemove,
    );
    if (!sure || !mounted) return;
    await _run(
      () => ref.read(spacesRepositoryProvider).removeFromTeam(
            _target,
            member.id,
          ),
      withdraw ? l10n.teamWithdrawn : l10n.teamRemoved,
    );
  }

  Future<void> _answer(TeamMember member, {required bool accept}) {
    final l10n = context.l10n;
    return _run(
      () => ref.read(spacesRepositoryProvider).answerTeamRequest(
            _target,
            member.id,
            accept: accept,
          ),
      accept ? l10n.teamRequestAccepted : l10n.teamRequestDeclined,
    );
  }

  Future<void> _toggleRequests({required bool value}) async {
    final failed = context.l10n.teamActionFailed;
    setState(() => _busy = true);
    try {
      await ref
          .read(spacesRepositoryProvider)
          .setAcceptsOrganizerRequests(_target, value: value);
      ref.invalidate(teamAcceptsRequestsProvider(_target));
    } on Object {
      if (mounted) showTopToast(context, failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = ref.watch(teamProvider(_target));
    final accepts =
        ref.watch(teamAcceptsRequestsProvider(_target)).asData?.value ?? false;
    final locale = Localizations.localeOf(context).toString();
    String date(DateTime when) => DateFormat.yMMMd(locale).format(when);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          _target.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: team.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.teamLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(teamProvider(_target)),
        ),
        data: (members) {
          final roster = TeamRoster(members);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _RequestsSwitch(
                value: accepts,
                busy: _busy,
                onChanged: (v) => _toggleRequests(value: v),
              ),
              if (roster.requests.isNotEmpty) ...[
                _Heading(l10n.teamRequests, color: AppColors.roleOrganizer),
                for (final m in roster.requests)
                  _MemberTile(
                    member: m,
                    note: m.expiresAt == null
                        ? null
                        : l10n.teamExpires(date(m.expiresAt!)),
                    actions: [
                      OutlinedButton(
                        onPressed:
                            _busy ? null : () => _answer(m, accept: false),
                        style: _smallButton,
                        child: Text(l10n.teamDecline),
                      ),
                      FilledButton(
                        onPressed:
                            _busy ? null : () => _answer(m, accept: true),
                        style: _smallButton,
                        child: Text(l10n.teamAccept),
                      ),
                    ],
                  ),
              ],
              _Heading(
                _kind == TeamKind.organizer
                    ? l10n.teamKindOrganizer
                    : l10n.teamKindHelper,
              ),
              _AddForm(
                kind: _kind,
                controller: _input,
                busy: _busy,
                onKind: (k) => setState(() => _kind = k),
                onChanged: _typed,
                onSubmit: _submit,
              ),
              if (_kind == TeamKind.organizer &&
                  !_input.text.contains('@') &&
                  _query.length >= 2)
                _OrganizerResults(
                  query: _query,
                  onTeam: roster.memberIds,
                  busy: _busy,
                  onInvite: _inviteFound,
                ),
              if (roster.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    l10n.teamEmpty,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                ),
              if (roster.active.isNotEmpty) ...[
                _Heading(l10n.teamOnTheTeam),
                for (final m in roster.active)
                  _MemberTile(
                    member: m,
                    note: m.respondedAt == null
                        ? null
                        : l10n.teamSince(date(m.respondedAt!)),
                    onRemove: _busy ? null : () => _remove(m, withdraw: false),
                    removeLabel: l10n.teamRemove,
                  ),
              ],
              if (roster.invited.isNotEmpty) ...[
                _Heading(l10n.teamWaiting),
                for (final m in roster.invited)
                  _MemberTile(
                    member: m,
                    note: m.expiresAt == null
                        ? null
                        : l10n.teamExpires(date(m.expiresAt!)),
                    onRemove: _busy ? null : () => _remove(m, withdraw: true),
                    removeLabel: l10n.teamWithdraw,
                  ),
              ],
              if (roster.past.isNotEmpty) ...[
                TextButton.icon(
                  onPressed: () => setState(() => _showPast = !_showPast),
                  icon: Icon(
                    _showPast
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(l10n.teamPast(roster.past.length)),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 44),
                  ),
                ),
                if (_showPast)
                  for (final m in roster.past)
                    _MemberTile(member: m, note: _pastLabel(l10n, m)),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A button that fits beside another in a row. The app theme makes buttons as
/// wide as their parent, which a row cannot give.
final ButtonStyle _smallButton = ButtonStyle(
  minimumSize: WidgetStateProperty.all(const Size(0, 40)),
  padding: WidgetStateProperty.all(
    const EdgeInsets.symmetric(horizontal: 14),
  ),
);

/// Why someone is no longer on the team.
String _pastLabel(AppLocalizations l10n, TeamMember member) =>
    switch (member.state) {
      'expired' => l10n.teamPastExpired,
      'declined' => l10n.teamPastDeclined,
      'finished' => l10n.teamPastFinished,
      _ => switch (member.endReason) {
          'left' => l10n.teamPastLeft,
          'role_revoked' => l10n.teamPastRevoked,
          _ => l10n.teamPastRemoved,
        },
    };

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.color = AppColors.textMuted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Text(text, style: AppTypography.label(color: color)),
    );
  }
}

class _RequestsSwitch extends StatelessWidget {
  const _RequestsSwitch({
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.teamAcceptsTitle,
                  style: AppTypography.display(size: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.teamAcceptsBody,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: busy ? null : onChanged),
        ],
      ),
    );
  }
}

class _AddForm extends StatelessWidget {
  const _AddForm({
    required this.kind,
    required this.controller,
    required this.busy,
    required this.onKind,
    required this.onChanged,
    required this.onSubmit,
  });

  final TeamKind kind;
  final TextEditingController controller;
  final bool busy;
  final ValueChanged<TeamKind> onKind;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final organizer = kind == TeamKind.organizer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TeamKind>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: TeamKind.organizer,
              label: Text(l10n.teamKindOrganizer),
            ),
            ButtonSegment(
              value: TeamKind.checkInHelper,
              label: Text(l10n.teamKindHelper),
            ),
          ],
          selected: {kind},
          onSelectionChanged: (s) => onKind(s.first),
        ),
        const SizedBox(height: 10),
        Text(
          organizer ? l10n.teamHintOrganizer : l10n.teamHintHelper,
          style: AppTypography.body(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          enabled: !busy,
          onChanged: onChanged,
          keyboardType:
              organizer ? TextInputType.text : TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText:
                organizer ? l10n.teamFieldOrganizer : l10n.teamFieldHelper,
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: busy || !controller.text.contains('@') ? null : onSubmit,
          child: Text(organizer ? l10n.teamSendInvite : l10n.teamAddHelper),
        ),
      ],
    );
  }
}

class _OrganizerResults extends ConsumerWidget {
  const _OrganizerResults({
    required this.query,
    required this.onTeam,
    required this.busy,
    required this.onInvite,
  });

  final String query;

  /// Accounts already on the team, invited or asking.
  final Set<String> onTeam;
  final bool busy;
  final ValueChanged<OrganizerCard> onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final found = ref.watch(organizerSearchProvider(query));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: found.when(
        loading: () => Text(
          l10n.teamSearching,
          style: AppTypography.body(color: AppColors.textMuted),
        ),
        error: (_, __) => Text(
          l10n.teamActionFailed,
          style: AppTypography.body(color: AppColors.error),
        ),
        data: (cards) => cards.isEmpty
            ? Text(
                l10n.teamNoMatches,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            : Column(
                children: [
                  for (final card in cards)
                    _OrganizerRow(
                      card: card,
                      already: onTeam.contains(card.id),
                      busy: busy,
                      onInvite: () => onInvite(card),
                    ),
                ],
              ),
      ),
    );
  }
}

class _OrganizerRow extends StatelessWidget {
  const _OrganizerRow({
    required this.card,
    required this.already,
    required this.busy,
    required this.onInvite,
  });

  final OrganizerCard card;
  final bool already;
  final bool busy;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final about = [card.city, ...card.specializations.map(_words)]
        .whereType<String>()
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Card(
        child: Row(
          children: [
            _Initial(card.name, color: AppColors.roleOrganizer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${card.name}  ${l10n.teamLevel(card.level)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 14),
                  ),
                  if (about.isNotEmpty)
                    Text(
                      about,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: busy || already ? null : onInvite,
              style: _smallButton,
              child: Text(already ? l10n.teamOnTeamAlready : l10n.teamInvite),
            ),
          ],
        ),
      ),
    );
  }

  /// `beach_resort` reads "Beach resort".
  static String _words(String category) {
    final words = category.replaceAll('_', ' ');
    return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    this.note,
    this.actions = const [],
    this.onRemove,
    this.removeLabel,
  });

  final TeamMember member;
  final String? note;

  /// Buttons under the person, for a request to answer.
  final List<Widget> actions;
  final VoidCallback? onRemove;
  final String? removeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = member.kind == TeamKind.organizer
        ? l10n.teamKindOrganizer
        : l10n.teamKindHelper;
    final detail = [member.email, if (note != null) note!].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Initial(member.title),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(size: 14),
                      ),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(kind, style: AppTypography.label()),
                    ],
                  ),
                ),
                if (removeLabel != null)
                  IconButton(
                    tooltip: removeLabel,
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.name, {this.color = AppColors.accent});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: AppTypography.display(size: 14, color: color),
      ),
    );
  }
}
