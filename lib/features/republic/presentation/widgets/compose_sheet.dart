import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The sheet for writing a post, or editing one when [initial] is given.
/// Resolves the text, or null when closed.
Future<String?> showComposeSheet(
  BuildContext context, {
  String initial = '',
  String? title,
  String? action,
  String? hint,
  bool allowEmpty = false,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ComposeSheet(
        initial: initial,
        title: title,
        action: action,
        hint: hint,
        allowEmpty: allowEmpty,
      ),
    );

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({
    required this.initial,
    required this.allowEmpty,
    this.title,
    this.action,
    this.hint,
  });

  final String initial;
  final String? title;
  final String? action;
  final String? hint;

  /// Whether it can be sent with nothing written, as a repost can.
  final bool allowEmpty;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? l10n.republicCompose,
            style: AppTypography.display(size: 20),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 5000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.hint ?? l10n.republicComposeHint,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.text.trim().isEmpty && !widget.allowEmpty
                  ? null
                  : () => Navigator.pop(context, _controller.text),
              child: Text(widget.action ?? l10n.republicPost),
            ),
          ),
        ],
      ),
    );
  }
}
