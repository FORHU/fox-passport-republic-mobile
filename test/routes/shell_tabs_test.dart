// The bottom bar passes its tab index straight to `goBranch`, so the shell
// branches must be in the same order as `RouteNames.shellTabs`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/routes/app_routes.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('shell branches open the screens the tab bar labels them as', () async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    final shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;
    final roots = [
      for (final branch in shell.branches)
        (branch.routes.first as GoRoute).path,
    ];

    expect(roots, RouteNames.shellTabs);
  });
}
