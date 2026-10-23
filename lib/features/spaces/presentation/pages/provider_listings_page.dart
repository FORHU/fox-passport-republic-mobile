import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_filters.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What a provider lists: gear for a Gear Foxer, services and performances
/// for a Service or Performer Foxer. Someone with both sees both, behind a
/// switch.
class ProviderListingsPage extends ConsumerStatefulWidget {
  const ProviderListingsPage({super.key});

  @override
  ConsumerState<ProviderListingsPage> createState() =>
      _ProviderListingsPageState();
}

class _ProviderListingsPageState extends ConsumerState<ProviderListingsPage> {
  final _search = TextEditingController();
  String _query = '';
  String? _group;

  /// Gear when true; otherwise services.
  bool _gear = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openOnWeb(String path) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp(path);
    if (!opened && mounted) showTopToast(context, message);
  }

  /// Adding and editing a listing is done on the web for now.
  Future<void> _showActions(SpaceListing listing) async {
    final l10n = context.l10n;
    final path = _gear
        ? '/creator-dashboard/assets/${listing.id}'
        : '/creator-dashboard/services/${listing.id}/edit';
    final edit = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.name, style: AppTypography.display(size: 18)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.providerListingEdit),
                onTap: () => Navigator.of(sheet).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (edit ?? false) await _openOnWeb(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roles = ref.watch(heldRolesProvider);
    final hasGear = roles.contains('gearFoxer');
    final hasServices =
        roles.contains('serviceFoxer') || roles.contains('performerFoxer');
    // Someone who holds only one of the two sees that one, with no switch.
    final gear = hasGear && (!hasServices || _gear);
    final provider = gear ? myAssetsProvider : myServicesProvider;
    final items = ref.watch(provider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.spaceTabListings),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(
          _openOnWeb(
            gear ? '/creator-dashboard/assets' : '/creator-dashboard/services',
          ),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.providerAddOnWeb),
      ),
      body: Column(
        children: [
          if (hasGear && hasServices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentedPills<bool>(
                value: gear,
                onChanged: (v) => setState(() {
                  _gear = v;
                  _group = null;
                }),
                options: [
                  SegmentOption(true, l10n.providerGear),
                  SegmentOption(false, l10n.providerServices),
                ],
              ),
            ),
          Expanded(
            child: items.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (_, __) => AppStateView(
                kind: AppStateKind.error,
                title: l10n.apiLoadFailed,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(provider),
              ),
              data: (all) {
                final counts = <String, int>{};
                for (final v in all) {
                  counts[v.group] = (counts[v.group] ?? 0) + 1;
                }
                final group = counts.containsKey(_group) ? _group : null;
                final shown = [
                  for (final v in all)
                    if ((group == null || v.group == group) &&
                        v.matches(_query))
                      v,
                ];
                return Column(
                  children: [
                    if (all.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: ListingSearchField(
                          controller: _search,
                          hint: l10n.providerSearchHint,
                          onChanged: (v) => setState(() => _query = v),
                          onClear: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ),
                      ListingFilterBar(
                        counts: counts,
                        total: all.length,
                        selected: group,
                        onSelected: (g) => setState(() => _group = g),
                      ),
                    ],
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.accent,
                        backgroundColor: AppColors.surface,
                        onRefresh: () => ref.refresh(provider.future),
                        child: shown.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      all.isEmpty
                                          ? (gear
                                              ? l10n.providerEmptyGear
                                              : l10n.providerEmptyServices)
                                          : l10n.venuesNoMatch,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.body(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 96),
                                itemCount: shown.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) => ListingCard(
                                  listing: shown[i],
                                  onTap: () =>
                                      unawaited(_showActions(shown[i])),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
