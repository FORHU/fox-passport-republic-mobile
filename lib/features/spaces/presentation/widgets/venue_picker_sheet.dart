import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Lets the person search for a venue and pick one. Venues in [taken] are
/// shown but cannot be picked. Gives back the venue, or null.
Future<CatalogItem?> pickVenue(
  BuildContext context, {
  Set<String> taken = const {},
}) {
  return showModalBottomSheet<CatalogItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => VenuePickerSheet(taken: taken),
  );
}

class VenuePickerSheet extends ConsumerStatefulWidget {
  const VenuePickerSheet({this.taken = const {}, super.key});

  final Set<String> taken;

  @override
  ConsumerState<VenuePickerSheet> createState() => _VenuePickerSheetState();
}

class _VenuePickerSheetState extends ConsumerState<VenuePickerSheet> {
  Timer? _debounce;
  String _query = '';
  Future<CatalogPage>? _results;

  @override
  void initState() {
    super.initState();
    _results = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<CatalogPage> _load() => ref
      .read(catalogRepositoryProvider)
      .fetch(CatalogKind.venues, query: _query, limit: 30);

  void _onChanged(String text) {
    _debounce?.cancel();
    // Wait for a pause in typing before asking the server.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _query = text.trim();
        _results = _load();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = MediaQuery.sizeOf(context).height * 0.8;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.partnersApplyTitle,
                    style: AppTypography.display(size: 18),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: _onChanged,
                    decoration: InputDecoration(
                      hintText: l10n.partnersSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<CatalogPage>(
                future: _results,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    );
                  }
                  final items = snapshot.data?.items ?? const <CatalogItem>[];
                  if (snapshot.hasError || items.isEmpty) {
                    return Center(
                      child: Text(
                        snapshot.hasError
                            ? l10n.apiLoadFailed
                            : l10n.partnersApplyNone,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final venue = items[i];
                      final taken = widget.taken.contains(venue.id);
                      return InkWell(
                        borderRadius: AppRadius.brCard,
                        onTap: taken
                            ? null
                            : () => Navigator.of(context).pop(venue),
                        child: Opacity(
                          opacity: taken ? 0.5 : 1,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: AppRadius.brCard,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                PhotoBox(
                                  url: venue.imageUrl,
                                  width: 48,
                                  height: 48,
                                  radius: 12,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        venue.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body(),
                                      ),
                                      Text(
                                        taken
                                            ? l10n.partnersAlready
                                            : venue.city ?? '',
                                        style: AppTypography.label(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
