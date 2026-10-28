import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/citizens/social_links.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// The links you have added to your other accounts, as chips you can tap to
/// change or remove, and a button to add one more. Nothing is saved here; the
/// edit screen saves with the rest of the form.
class SocialLinksEditor extends StatelessWidget {
  const SocialLinksEditor({
    required this.links,
    required this.onChanged,
    super.key,
  });

  final Map<SocialPlatform, String> links;
  final ValueChanged<Map<SocialPlatform, String>> onChanged;

  Future<void> _edit(BuildContext context, {SocialPlatform? platform}) async {
    final result = await showModalBottomSheet<(SocialPlatform, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _LinkSheet(
        editing: platform,
        current: platform == null ? '' : links[platform] ?? '',
        available: [
          for (final p in SocialPlatform.values)
            if (!links.containsKey(p)) p,
        ],
      ),
    );
    if (result == null) return;
    final (chosen, value) = result;
    final next = {...links};
    if (value.isEmpty) {
      next.remove(chosen);
    } else {
      next[chosen] = value;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canAdd = links.length < SocialPlatform.values.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.profileSocialTitle, style: AppTypography.display(size: 15)),
        const SizedBox(height: 2),
        Text(l10n.profileSocialHint, style: AppTypography.body(size: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in SocialPlatform.values)
              if (links.containsKey(p))
                InputChip(
                  avatar: FaIcon(p.icon, size: 14),
                  label: Text(p.label),
                  onPressed: () => _edit(context, platform: p),
                  onDeleted: () => onChanged({...links}..remove(p)),
                  deleteButtonTooltipMessage: l10n.profileSocialRemove,
                ),
            if (canAdd)
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.profileSocialAdd),
                onPressed: () => _edit(context),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinkSheet extends StatefulWidget {
  const _LinkSheet({
    required this.current,
    required this.available,
    this.editing,
  });

  /// The platform being changed, or null when adding one.
  final SocialPlatform? editing;
  final String current;

  /// The platforms not added yet.
  final List<SocialPlatform> available;

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  late final _controller = TextEditingController(text: widget.current);
  late SocialPlatform _platform = widget.editing ?? widget.available.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = _controller.text.trim();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editing?.label ?? l10n.profileSocialAdd,
              style: AppTypography.display(size: 18),
            ),
            const SizedBox(height: 14),
            // Choosing the platform is only for a new link.
            if (widget.editing == null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in widget.available)
                    ChoiceChip(
                      avatar: FaIcon(p.icon, size: 14),
                      label: Text(p.label),
                      selected: p == _platform,
                      onSelected: (_) => setState(() => _platform = p),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: _platform == SocialPlatform.website
                    ? l10n.profileSocialWebsiteHint
                    : l10n.profileSocialHandleHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.editing != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop((_platform, '')),
                    child: Text(
                      l10n.profileSocialRemove,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  onPressed: value.isEmpty
                      ? null
                      : () => Navigator.of(context).pop((_platform, value)),
                  child: Text(l10n.profileSocialDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
