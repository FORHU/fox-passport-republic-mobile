import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Opens a sheet to pick a Foxer and start a chat with them. Resolves to the
/// new (or existing) conversation id, or null when dismissed.
Future<String?> showNewChatSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _NewChatSheet(),
  );
}

class _NewChatSheet extends ConsumerStatefulWidget {
  const _NewChatSheet();

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  Timer? _debounce;
  String _query = '';
  bool _starting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _start(CatalogItem foxer) async {
    final l10n = context.l10n;
    if (foxer.isSample) {
      showTopToast(context, l10n.messageSampleFoxer);
      return;
    }
    setState(() => _starting = true);
    try {
      final id =
          await ref.read(messagesRepositoryProvider).startWithUser(foxer.id);
      ref.invalidate(conversationsProvider);
      if (mounted) Navigator.of(context).pop(id);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      showTopToast(
        context,
        e is AppException ? e.message : l10n.messageStartFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = ref.watch(
      catalogProvider(CatalogQuery(CatalogKind.foxers, query: _query)),
    );
    final height = MediaQuery.sizeOf(context).height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.messageNewChatTitle,
                        style: AppTypography.display(size: 18),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.bookClose,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: _onQuery,
                  cursorColor: AppColors.accent,
                  style: AppTypography.body(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.messageNewChatSearch,
                    hintStyle: AppTypography.body(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.canvas,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.brPill,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.brPill,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.brPill,
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: results.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      l10n.messagesLoadFailed,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.messageNewChatEmpty,
                          style: AppTypography.body(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: page.items.length,
                      itemBuilder: (context, index) => _FoxerTile(
                        foxer: page.items[index],
                        enabled: !_starting,
                        onTap: () => _start(page.items[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoxerTile extends StatelessWidget {
  const _FoxerTile({
    required this.foxer,
    required this.enabled,
    required this.onTap,
  });

  final CatalogItem foxer;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = foxerRoleLabel(context.l10n, foxer.roles);
    final initial = foxer.title.isEmpty ? '?' : foxer.title[0].toUpperCase();
    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceRaised,
        backgroundImage: foxer.imageUrl == null
            ? null
            : NetworkImage(resolveAssetUrl(foxer.imageUrl!)),
        child: foxer.imageUrl == null
            ? Text(initial, style: AppTypography.display())
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              foxer.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(size: 15),
            ),
          ),
          if (foxer.verified) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.verified_rounded,
              size: 15,
              color: AppColors.accent,
            ),
          ],
        ],
      ),
      subtitle: role == null
          ? null
          : Text(
              role,
              style: AppTypography.body(
                size: 12,
                color: AppColors.roleLabel,
                weight: FontWeight.w600,
              ),
            ),
    );
  }
}
