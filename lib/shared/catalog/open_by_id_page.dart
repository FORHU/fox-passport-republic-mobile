import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// Opens a venue, event package or Foxer from a link that carries only its id:
/// loads the row, then shows the same page a tap in Search would. While it
/// loads there is a spinner; if it cannot be read there is a retry, and if it
/// is not there a way back to Search.
class OpenByIdPage extends ConsumerWidget {
  const OpenByIdPage({
    required this.kind,
    required this.id,
    required this.builder,
    super.key,
  });

  final CatalogKind kind;
  final String id;
  final Widget Function(CatalogItem item) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final which = (kind: kind, id: id);
    final item = ref.watch(catalogItemByIdProvider(which));

    return item.when(
      data: (found) => found == null
          ? _Frame(
              child: AppStateView(
                title: l10n.openByIdNotFound,
                actionLabel: l10n.openByIdToSearch,
                onAction: () => context.go(RouteNames.search),
              ),
            )
          : builder(found),
      loading: () => const _Frame(
        child:
            Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (_, __) => _Frame(
        child: AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(catalogItemByIdProvider(which)),
        ),
      ),
    );
  }
}

/// A bare page with a back button, for the states before the real page.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(),
        body: child,
      );
}
