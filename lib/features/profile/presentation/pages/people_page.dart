import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/person.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Your followers, the people you follow, and the follow requests waiting on
/// you.
class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserIdProvider);

    return DefaultTabController(
      length: PeopleList.values.length,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(l10n.peopleTitle, style: AppTypography.display(size: 18)),
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: l10n.peopleFollowers),
              Tab(text: l10n.peopleFollowing),
              Tab(text: l10n.peopleRequests),
            ],
          ),
        ),
        body: me == null
            ? const SizedBox.shrink()
            : TabBarView(
                children: [
                  for (final list in PeopleList.values)
                    _PeopleTab(userId: me, list: list),
                ],
              ),
      ),
    );
  }
}

class _PeopleTab extends ConsumerWidget {
  const _PeopleTab({required this.userId, required this.list});

  final String userId;
  final PeopleList list;

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    Person person, {
    required bool accept,
  }) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(peopleProvider((userId: userId, list: list)).notifier)
          .answer(person.id, accept: accept);
      // A new follower belongs in the followers list too.
      if (accept) {
        ref.invalidate(
          peopleProvider((userId: userId, list: PeopleList.followers)),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.peopleAnswerFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (userId: userId, list: list);
    final async = ref.watch(peopleProvider(key));

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.peopleLoadFailed,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: () => ref.invalidate(peopleProvider(key)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (people) {
        if (people.isEmpty) {
          return Center(
            child: Text(
              switch (list) {
                PeopleList.followers => l10n.peopleEmptyFollowers,
                PeopleList.following => l10n.peopleEmptyFollowing,
                PeopleList.requests => l10n.peopleEmptyRequests,
              },
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.refresh(peopleProvider(key).future),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: people.length,
            itemBuilder: (context, i) => _PersonRow(
              person: people[i],
              onAccept: list == PeopleList.requests
                  ? () => _answer(context, ref, people[i], accept: true)
                  : null,
              onDecline: list == PeopleList.requests
                  ? () => _answer(context, ref, people[i], accept: false)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, this.onAccept, this.onDecline});

  final Person person;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = person.name.isEmpty ? person.username : person.name;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return ListTile(
      leading: AvatarImage(
        url: person.imageUrl,
        radius: 22,
        fallback: Text(initial, style: AppTypography.display()),
      ),
      title:
          Text(name, style: AppTypography.body(color: AppColors.textPrimary)),
      subtitle: person.username.isEmpty || person.name.isEmpty
          ? null
          : Text('@${person.username}', style: AppTypography.body(size: 13)),
      trailing: onAccept == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onDecline,
                  child: Text(l10n.peopleDecline),
                ),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                  ),
                  child: Text(l10n.peopleAccept),
                ),
              ],
            ),
    );
  }
}
