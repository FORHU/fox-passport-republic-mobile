import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_filters.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What a provider lists: gear in the Gear space, services (and performances)
/// in the Services space.
class ProviderListingsPage extends ConsumerStatefulWidget {
  const ProviderListingsPage({required this.kind, super.key});

  final ProviderKind kind;

  @override
  ConsumerState<ProviderListingsPage> createState() =>
      _ProviderListingsPageState();
}

class _ProviderListingsPageState extends ConsumerState<ProviderListingsPage> {
  final _search = TextEditingController();
  String _query = '';
  String? _group;

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
    final path = widget.kind.webEdit(listing.id);
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
    final gear = widget.kind.isGear;
    final provider = gear ? myAssetsProvider : myServicesProvider;
    final items = ref.watch(provider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(
        title: listingsLabel(l10n, widget.kind, roles: roles),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_openOnWeb(widget.kind.webAdd)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.providerAddOnWeb),
      ),
      body: Column(
        children: [
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
