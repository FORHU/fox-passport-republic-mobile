import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/event_detail.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/event_studio_controller.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Opens the list of things to put in an event: venues, talent, services and
/// equipment. [studioId] is the event being built (null for a new one).
Future<void> showPackagePicker(
  BuildContext context, {
  required String? studioId,
  ResourceBucket start = ResourceBucket.venue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => PackagePickerSheet(studioId: studioId, start: start),
  );
}

/// The words for each way adding can be refused, as the web words them.
String? addToast(AppLocalizations l10n, AddResult result, String name) =>
    switch (result) {
      AddResult.added => l10n.esToastAdded(name),
      AddResult.duplicate => l10n.esToastDuplicate(name),
      AddResult.alreadyHasVenue => l10n.esToastOneVenue,
      AddResult.venuePending => l10n.esToastVenuePending,
      AddResult.venueNotApplied => l10n.esToastVenueApply,
    };

class PackagePickerSheet extends ConsumerStatefulWidget {
  const PackagePickerSheet({
    required this.studioId,
    this.start = ResourceBucket.venue,
    super.key,
  });

  final String? studioId;
  final ResourceBucket start;

  @override
  ConsumerState<PackagePickerSheet> createState() => _PackagePickerSheetState();
}

class _PackagePickerSheetState extends ConsumerState<PackagePickerSheet> {
  late ResourceBucket _bucket = widget.start;
  Timer? _debounce;
  String _query = '';

  // Venues are searched on the server, a page at a time.
  final _venues = <PackageItem>[];
  int _venuePage = 0;
  int _venueTotal = 0;
  bool _venuesLoading = false;
  bool _venuesFailed = false;

  // Assets and services are loaded a page at a time and searched here.
  final _supplies = <PackageItem>[];
  int _supplyPage = 0;
  int _assetTotal = 0;
  int _serviceTotal = 0;
  bool _suppliesLoading = false;
  bool _suppliesFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMore());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  bool get _isVenues => _bucket == ResourceBucket.venue;

  bool get _hasMore => _isVenues
      ? _venuePage * 50 < _venueTotal
      : _supplyPage * 50 < _assetTotal || _supplyPage * 50 < _serviceTotal;

  bool get _loading => _isVenues ? _venuesLoading : _suppliesLoading;

  Future<void> _loadMore({bool reset = false}) async {
    if (_isVenues) {
      if (_venuesLoading) return;
      if (reset) {
        _venues.clear();
        _venuePage = 0;
        _venueTotal = 0;
      } else if (_venuePage > 0 && !_hasMore) {
        return;
      }
      setState(() {
        _venuesLoading = true;
        _venuesFailed = false;
      });
      try {
        final page = await _repo.venueChoices(
          query: _query,
          page: _venuePage + 1,
        );
        if (!mounted) return;
        setState(() {
          _venues.addAll(page.items);
          _venuePage += 1;
          _venueTotal = page.total;
          _venuesLoading = false;
        });
      } on Object {
        if (!mounted) return;
        setState(() {
          _venuesLoading = false;
          _venuesFailed = true;
        });
      }
    } else {
      if (_suppliesLoading) return;
      if (_supplyPage > 0 && !_hasMore) return;
      setState(() {
        _suppliesLoading = true;
        _suppliesFailed = false;
      });
      try {
        final next = _supplyPage + 1;
        final assets = await _repo.assetChoices(page: next);
        final services = await _repo.serviceChoices(page: next);
        if (!mounted) return;
        setState(() {
          _supplies
            ..addAll(assets.items)
            ..addAll(services.items);
          _supplyPage = next;
          _assetTotal = assets.total;
          _serviceTotal = services.total;
          _suppliesLoading = false;
        });
      } on Object {
        if (!mounted) return;
        setState(() {
          _suppliesLoading = false;
          _suppliesFailed = true;
        });
      }
    }
  }

  void _pickBucket(ResourceBucket bucket) {
    if (bucket == _bucket) return;
    setState(() => _bucket = bucket);
    // The first time a supply tab is opened, its lists are fetched.
    if (bucket != ResourceBucket.venue && _supplyPage == 0) {
      unawaited(_loadMore());
    }
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    // Wait for a pause in typing before asking the server.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final changed = text.trim() != _query;
      setState(() => _query = text.trim());
      if (changed && _isVenues) unawaited(_loadMore(reset: true));
    });
  }

  void _add(PackageItem item) {
    final l10n = context.l10n;
    final result =
        ref.read(eventStudioProvider(widget.studioId).notifier).addItem(
              item,
            );
    final message = addToast(l10n, result, item.name);
    if (message != null) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final studio = ref.watch(eventStudioProvider(widget.studioId));
    final money = ref.watch(moneyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final added = {for (final i in studio.draft.items) i.id};

    final needle = _query.toLowerCase();
    final items = _isVenues
        ? _venues
        : [
            for (final i in _supplies)
              if (bucketOf(i) == _bucket &&
                  (needle.isEmpty || i.name.toLowerCase().contains(needle)))
                i,
          ];
    final failed = _isVenues ? _venuesFailed : _suppliesFailed;

    final labels = {
      ResourceBucket.venue: l10n.esPickVenues,
      ResourceBucket.talent: l10n.esPickTalent,
      ResourceBucket.service: l10n.esPickServices,
      ResourceBucket.equipment: l10n.esPickEquipment,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in labels.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _bucket == entry.key,
                        onSelected: (_) => _pickBucket(entry.key),
                        selectedColor: AppColors.accent,
                        labelStyle: AppTypography.label(
                          color: _bucket == entry.key
                              ? AppColors.onAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: l10n.esPickSearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  for (final item in items) ...[
                    _Row(
                      item: item,
                      price: money.format(
                        item.cost,
                        kBaseCurrency,
                        locale: locale,
                      ),
                      added: added.contains(item.id),
                      access: item.isVenue ? studio.accessFor(item.id) : null,
                      onTap: () => _add(item),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  else if (failed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: TextButton(
                          onPressed: () => unawaited(_loadMore()),
                          child: Text(l10n.retry),
                        ),
                      ),
                    )
                  else if (items.isEmpty && !_hasMore)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.esPickNone,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    ),
                  if (!_loading && !failed && _hasMore)
                    Center(
                      child: TextButton(
                        onPressed: () => unawaited(_loadMore()),
                        child: Text(l10n.esPickMore),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.price,
    required this.added,
    required this.access,
    required this.onTap,
  });

  final PackageItem item;
  final String price;
  final bool added;

  /// A venue's access for the host; null for anything else.
  final VenueAccess? access;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String? tag;
    final Color tagColor;
    if (added) {
      tag = l10n.esAdded;
      tagColor = AppColors.success;
    } else {
      switch (access) {
        case VenueAccess.approved:
          tag = l10n.esAccessApproved;
          tagColor = AppColors.success;
        case VenueAccess.pending:
          tag = l10n.esAccessPending;
          tagColor = AppColors.warning;
        case VenueAccess.none:
          tag = l10n.esAccessApply;
          tagColor = AppColors.textMuted;
        case null:
          tag = null;
          tagColor = AppColors.textMuted;
      }
    }
    final subtitle = item.isVenue
        ? [item.city, item.state].whereType<String>().join(', ')
        : item.description;
    return Material(
      color: AppColors.canvas,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PhotoBox(url: item.imageUrl, width: 48, height: 48, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: AppTypography.body(size: 13)),
                  if (tag != null)
                    Text(tag, style: AppTypography.label(color: tagColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
