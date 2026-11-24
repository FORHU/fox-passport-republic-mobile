import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/open_packages_repository.dart';
import 'package:flutter_template/features/spaces/domain/open_package.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_invites.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Open packages and applications (mobile#494, api#460), from the canvas
/// page "Open packages": the list, a package's spots, applying with a
/// listing, and the Event Foxer's applications.

/// A spot in words: "Venue", or its category, "Photography".
String spotLabel(AppLocalizations l10n, String spot) =>
    Spot.isVenue(spot) ? l10n.openSpotVenue : Spot.category(spot);

String _error(AppLocalizations l10n, Object e) =>
    e is AppException && e.message.isNotEmpty ? e.message : l10n.inviteFailed;

String _money(BuildContext context, WidgetRef ref, num price) =>
    ref.read(moneyFormatterProvider).format(
          price,
          kBaseCurrency,
          locale: Localizations.localeOf(context).toString(),
        );

Widget _chip(String label, {required bool open}) => Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: open ? AppColors.accentTintBg : AppColors.clear,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: open ? AppColors.accentTintBorder : AppColors.borderStrong,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.body(
          size: 12,
          color: open ? AppColors.accent : AppColors.textMuted,
        ),
      ),
    );

/// Packages other Event Foxers are putting together.
class OpenPackagesPage extends ConsumerWidget {
  const OpenPackagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.openPackagesTitle, style: AppTypography.display()),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.refresh(openPackagesProvider.future),
        child: ref.watch(openPackagesProvider).when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (_, __) => AppStateView(
                kind: AppStateKind.error,
                title: l10n.apiLoadFailed,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(openPackagesProvider),
              ),
              data: (packages) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text(l10n.openPackagesHint, style: AppTypography.body()),
                  const SizedBox(height: 12),
                  if (packages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        l10n.openPackagesEmpty,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    ),
                  for (final p in packages) ...[
                    _OpenPackageCard(package: p),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}

class _OpenPackageCard extends StatelessWidget {
  const _OpenPackageCard({required this.package});

  final OpenPackage package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = package;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => OpenPackagePage(id: p.id)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(p.name, style: AppTypography.display()),
                  ),
                  if (p.city != null && p.city!.isNotEmpty)
                    Text(p.city!, style: AppTypography.body(size: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (p.hostName != null) p.hostName!,
                  if (p.maxAttendees != null)
                    l10n.openUpToGuests(p.maxAttendees!),
                ].join(' · '),
                style: AppTypography.body(size: 12),
              ),
              if (p.takenSpots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in p.takenSpots)
                      _chip(
                        l10n.openSpotTaken(spotLabel(l10n, s)),
                        open: false,
                      ),
                  ],
                ),
              ],
              if (p.waiting != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.openYouApplied,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One open package: what it has, and applying with one of your listings.
class OpenPackagePage extends ConsumerWidget {
  const OpenPackagePage({required this.id, super.key});

  final String id;

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    MyApplication app,
  ) async {
    final l10n = context.l10n;
    try {
      await ref.read(openPackagesRepositoryProvider).withdraw(id, app.id);
      ref
        ..invalidate(openPackageProvider(id))
        ..invalidate(openPackagesProvider);
      if (context.mounted) showTopToast(context, l10n.openWithdrawn);
    } on Object catch (e) {
      if (context.mounted) showTopToast(context, _error(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.openPackageTitle, style: AppTypography.display()),
      ),
      body: ref.watch(openPackageProvider(id)).when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (_, __) => AppStateView(
              kind: AppStateKind.error,
              title: l10n.apiLoadFailed,
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(openPackageProvider(id)),
            ),
            data: (p) {
              final waiting = p.waiting;
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        if (p.hostName != null)
                          Text(
                            p.hostName!.toUpperCase(),
                            style: AppTypography.label(),
                          ),
                        const SizedBox(height: 4),
                        Text(p.name, style: AppTypography.display(size: 22)),
                        if (p.description != null) ...[
                          const SizedBox(height: 6),
                          Text(p.description!, style: AppTypography.body()),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          l10n.openSpotsTitle.toUpperCase(),
                          style: AppTypography.label(),
                        ),
                        const SizedBox(height: 10),
                        if (p.lines.isEmpty)
                          Text(
                            l10n.openNoLines,
                            style: AppTypography.body(
                              color: AppColors.textMuted,
                            ),
                          ),
                        for (final line in p.lines) ...[
                          _SpotRow(line: line),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          l10n.openSpotFrees,
                          style: AppTypography.body(
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: waiting != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.openYouApplied,
                                style: AppTypography.body(
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _withdraw(context, ref, waiting),
                                  child: Text(l10n.openWithdraw),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: p.choices.isEmpty
                                  ? null
                                  : () => showApplySheet(context, p),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.onAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.brMd,
                                ),
                              ),
                              child: Text(
                                p.choices.isEmpty
                                    ? l10n.openNoListings
                                    : l10n.openApply,
                                style: AppTypography.display(
                                  size: 15,
                                  color: AppColors.onAccent,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _SpotRow extends StatelessWidget {
  const _SpotRow({required this.line});

  final OpenPackageLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  spotLabel(l10n, line.spot),
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
                Text(
                  [
                    line.name,
                    if (line.isOptional) l10n.esOptional,
                  ].join(' · '),
                  style: AppTypography.body(size: 12),
                ),
              ],
            ),
          ),
          Text(
            l10n.openTaken,
            style: AppTypography.body(size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Picks one of your listings and sends the application.
Future<void> showApplySheet(BuildContext context, OpenPackageDetail p) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ApplySheet(package: p),
    );

class _ApplySheet extends ConsumerStatefulWidget {
  const _ApplySheet({required this.package});

  final OpenPackageDetail package;

  @override
  ConsumerState<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends ConsumerState<_ApplySheet> {
  ApplyChoice? _choice;
  final _message = TextEditingController();
  bool _sending = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _choice = widget.package.choices.where((c) => c.canApply).firstOrNull;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final choice = _choice;
    if (choice == null) return;
    final l10n = context.l10n;
    setState(() {
      _sending = true;
      _problem = null;
    });
    try {
      await ref
          .read(openPackagesRepositoryProvider)
          .apply(widget.package.id, choice, message: _message.text);
      ref
        ..invalidate(openPackageProvider(widget.package.id))
        ..invalidate(openPackagesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showTopToast(context, l10n.openApplied);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _problem = _error(l10n, e);
      });
    }
  }

  String? _blocked(AppLocalizations l10n, ApplyChoice c) => switch (c.block) {
        ApplyBlock.spotTaken => l10n.openChoiceTaken(spotLabel(l10n, c.spot)),
        ApplyBlock.alreadyApplied => l10n.openChoiceApplied,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = widget.package;
    final error = _problem;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.openApplyTitle, style: AppTypography.display(size: 20)),
            const SizedBox(height: 6),
            Text(
              [p.name, if (p.hostName != null) p.hostName!].join(' · '),
              style: AppTypography.body(size: 13),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.openYourListing.toUpperCase(),
              style: AppTypography.label(),
            ),
            const SizedBox(height: 8),
            RadioGroup<ApplyChoice>(
              groupValue: _choice,
              onChanged: (c) {
                if (c != null && c.canApply) setState(() => _choice = c);
              },
              child: Column(
                children: [
                  for (final c in p.choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ChoiceTile(
                        choice: c,
                        selected: _choice == c,
                        blocked: _blocked(l10n, c),
                        price: c.price == null
                            ? null
                            : _money(context, ref, c.price!),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              l10n.openPriceIsYours,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(l10n.openMessageLabel, style: AppTypography.body(size: 13)),
            const SizedBox(height: 6),
            TextField(
              key: const Key('open-apply-message'),
              controller: _message,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(counterText: ''),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTypography.body(size: 13, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _choice != null && !_sending ? _send : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                ),
                child: Text(
                  l10n.openSend,
                  style: AppTypography.display(color: AppColors.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    this.blocked,
    this.price,
  });

  final ApplyChoice choice;
  final bool selected;

  /// Why it can't apply, when it can't.
  final String? blocked;
  final String? price;

  @override
  Widget build(BuildContext context) {
    final enabled = blocked == null;
    final color = enabled ? AppColors.textPrimary : AppColors.textFaint;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceRaised : AppColors.canvas,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: selected ? AppColors.textPrimary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Radio<ApplyChoice>(value: choice, enabled: enabled),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(choice.name, style: AppTypography.body(color: color)),
                Text(
                  blocked ?? spotLabel(context.l10n, choice.spot),
                  style: AppTypography.body(
                    size: 12,
                    color: enabled ? AppColors.textMuted : AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          if (price != null)
            Text(price!, style: AppTypography.body(size: 13, color: color)),
        ],
      ),
    );
  }
}

/// Applications to the Event Foxer's own package: accept or decline.
class PackageApplicationsPage extends ConsumerWidget {
  const PackageApplicationsPage({
    required this.templateId,
    required this.packageName,
    super.key,
  });

  final String templateId;
  final String packageName;

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    PackageApplication a,
  ) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(openPackagesRepositoryProvider)
          .answer(templateId, a.id, accept: true);
      ref.invalidate(packageApplicationsProvider(templateId));
      if (context.mounted) {
        showTopToast(context, l10n.openAccepted(a.listingName));
      }
    } on Object catch (e) {
      if (context.mounted) showTopToast(context, _error(l10n, e));
    }
  }

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    PackageApplication a,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(openPackagesRepositoryProvider);
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => DeclineReasonSheet(
        title: l10n.openDeclineTitle,
        subtitle: '${a.listingName} · ${a.applicantName}',
        seenBy: l10n.openDeclineSeen,
        onDecline: (reason, note) async {
          try {
            await repo.answer(
              templateId,
              a.id,
              accept: false,
              reason: reason,
              note: note,
            );
            return null;
          } on Object catch (e) {
            return e is AppException ? e.message : '';
          }
        },
      ),
    );
    if (done == true) ref.invalidate(packageApplicationsProvider(templateId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.openApplicationsTitle, style: AppTypography.display()),
      ),
      body: ref.watch(packageApplicationsProvider(templateId)).when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (_, __) => AppStateView(
              kind: AppStateKind.error,
              title: l10n.apiLoadFailed,
              actionLabel: l10n.retry,
              onAction: () =>
                  ref.invalidate(packageApplicationsProvider(templateId)),
            ),
            data: (apps) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(packageName.toUpperCase(), style: AppTypography.label()),
                const SizedBox(height: 6),
                Text(l10n.openAcceptCloses, style: AppTypography.body()),
                const SizedBox(height: 14),
                if (apps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      l10n.openNoApplications,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                  ),
                for (final a in apps) ...[
                  _ApplicationCard(
                    application: a,
                    price:
                        a.price == null ? null : _money(context, ref, a.price!),
                    onAccept: () => _accept(context, ref, a),
                    onDecline: () => _decline(context, ref, a),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onAccept,
    required this.onDecline,
    this.price,
  });

  final PackageApplication application;
  final String? price;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = application;
    final waiting = a.status == ApplicationStatus.pending;
    final status = switch (a.status) {
      ApplicationStatus.accepted => l10n.esInviteAccepted,
      ApplicationStatus.declined => l10n.esInviteDeclined,
      ApplicationStatus.withdrawn => l10n.openWithdrawnStatus,
      ApplicationStatus.pending => null,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(a.listingName, style: AppTypography.display(size: 15)),
              ),
              if (price != null)
                Text(
                  price!,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              a.applicantName,
              if (a.spot != null) spotLabel(l10n, a.spot!),
            ].join(' · '),
            style: AppTypography.body(size: 12),
          ),
          if (a.message != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.brMd,
              ),
              child: Text(
                '“${a.message}”',
                style:
                    AppTypography.body(size: 13, color: AppColors.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (!waiting)
            Text(
              status ?? '',
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            )
          else if (a.spotTaken)
            Text(
              l10n.openSpotFilled,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      child: Text(l10n.openAccept),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onDecline,
                      child: Text(l10n.inviteDecline),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
