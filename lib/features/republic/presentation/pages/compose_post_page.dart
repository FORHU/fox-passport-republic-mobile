import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/media_picker.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/new_post.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Writing a post: the words, photos, who can see it, and, for a poll or a
/// venue spotlight, what goes with it. Pops `true` once it is posted.
class ComposePostPage extends ConsumerStatefulWidget {
  const ComposePostPage({super.key});

  @override
  ConsumerState<ComposePostPage> createState() => _ComposePostPageState();
}

/// The words field has no outline, but rounded corners like the other fields.
final _roundedBorder = OutlineInputBorder(
  borderRadius: AppRadius.brMd,
  borderSide: BorderSide.none,
);

class _ComposePostPageState extends ConsumerState<ComposePostPage> {
  static const _maxPhotos = 10;

  final _text = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];

  ComposeType _type = ComposeType.story;
  PostVisibility _visibility = PostVisibility.public;
  final _photos = <PickedMedia>[];
  String? _venueId;
  bool _posting = false;

  String? _mention;
  List<MentionCandidate> _candidates = const [];
  Timer? _mentionTimer;

  @override
  void dispose() {
    _mentionTimer?.cancel();
    _text.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  RepublicRepository get _repo => ref.read(republicRepositoryProvider);

  List<String> get _pollOptions => [
        for (final o in _options)
          if (o.text.trim().isNotEmpty) o.text.trim(),
      ];

  bool get _pollValid {
    if (_type != ComposeType.poll) return true;
    final options = _pollOptions;
    return options.length >= 2 &&
        {for (final o in options) o.toLowerCase()}.length == options.length;
  }

  bool get _canPost =>
      !_posting &&
      (_text.text.trim().isNotEmpty || _photos.isNotEmpty) &&
      _pollValid &&
      (_type != ComposeType.venueSpotlight || _venueId != null);

  void _onChanged(String value) {
    final cursor = _text.selection.baseOffset;
    final before = cursor < 0 ? value : value.substring(0, cursor);
    final query = mentionQueryAt(before);
    _mentionTimer?.cancel();
    if (query == null) {
      setState(() {
        _mention = null;
        _candidates = const [];
      });
      return;
    }
    setState(() => _mention = query);
    _mentionTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final found = await _repo.mentionCandidates(query);
        if (mounted && _mention == query) setState(() => _candidates = found);
      } on Object {
        if (mounted) setState(() => _candidates = const []);
      }
    });
  }

  void _insertMention(MentionCandidate c) {
    final cursor = _text.selection.baseOffset.clamp(0, _text.text.length);
    final before = _text.text.substring(0, cursor);
    final after = _text.text.substring(cursor);
    final replaced = before.replaceFirst(RegExp(r'@[A-Za-z0-9_]{0,32}$'), '');
    final inserted = '$replaced@${c.handle} ';
    _text.value = TextEditingValue(
      text: inserted + after,
      selection: TextSelection.collapsed(offset: inserted.length),
    );
    setState(() {
      _mention = null;
      _candidates = const [];
    });
  }

  Future<void> _addPhotos() async {
    final room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    final picked = await ref.read(mediaPickerProvider).pickMany(room);
    if (picked.isEmpty || !mounted) return;
    setState(() => _photos.addAll(picked.take(room)));
  }

  Future<void> _post() async {
    final l10n = context.l10n;
    if (!_canPost) return;
    setState(() => _posting = true);
    try {
      final urls = <String>[];
      for (final photo in _photos) {
        urls.add(await _repo.uploadMedia(photo));
      }
      await _repo.createPost(
        NewPost(
          type: _type,
          content: _text.text,
          mediaUrls: urls,
          visibility: _visibility,
          venueId: _type == ComposeType.venueSpotlight ? _venueId : null,
          pollOptions: _pollOptions,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        showTopToast(
          context,
          e is AppException ? e.message : l10n.republicPostFailed,
        );
      }
    }
  }

  String _typeLabel(AppLocalizations l10n, ComposeType t) => switch (t) {
        ComposeType.story => l10n.republicTypeStory,
        ComposeType.poll => l10n.republicTypePoll,
        ComposeType.venueSpotlight => l10n.republicTypeVenue,
      };

  String _visibilityLabel(AppLocalizations l10n, PostVisibility v) =>
      switch (v) {
        PostVisibility.public => l10n.republicVisibilityPublic,
        PostVisibility.followers => l10n.republicVisibilityFollowers,
        PostVisibility.onlyMe => l10n.republicVisibilityOnlyMe,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authControllerProvider).user;
    final types = [
      ComposeType.story,
      ComposeType.poll,
      if (user?.hasRole('venueFoxer') ?? false) ComposeType.venueSpotlight,
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: _posting ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(l10n.republicCompose),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                onPressed: _canPost ? _post : null,
                child:
                    Text(_posting ? l10n.republicPosting : l10n.republicPost),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              AuthorAvatar(
                author: PostAuthor(
                  id: user?.id ?? '',
                  name: user?.name ?? '',
                  imageUrl: user?.imageUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: AppTypography.body(weight: FontWeight.w700),
                    ),
                    PopupMenuButton<PostVisibility>(
                      tooltip: l10n.republicVisibility,
                      initialValue: _visibility,
                      onSelected: (v) => setState(() => _visibility = v),
                      itemBuilder: (_) => [
                        for (final v in PostVisibility.values)
                          PopupMenuItem(
                            value: v,
                            child: Text(_visibilityLabel(l10n, v)),
                          ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            switch (_visibility) {
                              PostVisibility.public => Icons.public_rounded,
                              PostVisibility.followers => Icons.group_outlined,
                              PostVisibility.onlyMe => Icons.lock_outline,
                            },
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _visibilityLabel(l10n, _visibility),
                            style: AppTypography.body(
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (types.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final t in types)
                  ChoiceChip(
                    label: Text(_typeLabel(l10n, t)),
                    selected: _type == t,
                    onSelected:
                        _posting ? null : (_) => setState(() => _type = t),
                  ),
              ],
            ),
          ],
          if (_type == ComposeType.venueSpotlight) ...[
            const SizedBox(height: 12),
            _VenuePicker(
              userId: user?.id,
              value: _venueId,
              onChanged: (id) => setState(() => _venueId = id),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            enabled: !_posting,
            maxLines: null,
            minLines: 5,
            maxLength: 5000,
            onChanged: _onChanged,
            decoration: InputDecoration(
              border: _roundedBorder,
              enabledBorder: _roundedBorder,
              focusedBorder: _roundedBorder,
              hintText: _type == ComposeType.poll
                  ? l10n.republicPollHint
                  : l10n.republicComposeHint,
            ),
          ),
          if (_mention != null && _candidates.isNotEmpty)
            Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final c in _candidates.take(5))
                    ListTile(
                      dense: true,
                      leading: AuthorAvatar(
                        author: PostAuthor(
                          id: c.id,
                          name: c.name,
                          imageUrl: c.imageUrl,
                        ),
                        size: 28,
                      ),
                      title: Text(c.name),
                      subtitle:
                          c.username == null ? null : Text('@${c.username}'),
                      onTap: () => _insertMention(c),
                    ),
                ],
              ),
            ),
          if (_type == ComposeType.poll) ...[
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        enabled: !_posting,
                        maxLength: 120,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            null,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.republicPollOption(i + 1),
                        ),
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        onPressed: () => setState(() {
                          _options.removeAt(i).dispose();
                        }),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                  ],
                ),
              ),
            if (_options.length < 10)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _options.add(TextEditingController()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.republicAddOption),
                ),
              ),
          ],
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _photos[i].bytes,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        cacheWidth: 264,
                      ),
                    ),
                    if (!_posting)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.scrim,
                            child: Icon(Icons.close_rounded, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed:
                  _posting || _photos.length >= _maxPhotos ? null : _addPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _photos.isEmpty
                    ? l10n.republicAddPhotos
                    : l10n.republicPhotoCount(_photos.length, _maxPhotos),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The person's venues, to choose the one a spotlight is about.
class _VenuePicker extends ConsumerWidget {
  const _VenuePicker({
    required this.userId,
    required this.value,
    required this.onChanged,
  });

  final String? userId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = userId;
    if (id == null) return const SizedBox.shrink();
    final venues = ref.watch(_myVenuesProvider(id));
    return venues.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => Text(l10n.republicActionFailed),
      data: (list) => list.isEmpty
          ? Text(
              l10n.republicNoVenues,
              style: AppTypography.body(color: AppColors.textMuted),
            )
          : DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              hint: Text(l10n.republicChooseVenue),
              items: [
                for (final v in list)
                  DropdownMenuItem(value: v.id, child: Text(v.name)),
              ],
              onChanged: onChanged,
            ),
    );
  }
}

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final _myVenuesProvider =
    FutureProvider.autoDispose.family<List<VenueChoice>, String>(
  (ref, userId) => ref.watch(republicRepositoryProvider).myVenues(userId),
);
