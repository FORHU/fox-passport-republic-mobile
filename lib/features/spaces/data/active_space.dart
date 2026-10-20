import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';

/// The roles the signed-in person holds.
final Provider<List<String>> heldRolesProvider = Provider<List<String>>(
  (ref) => ref.watch(
    authControllerProvider.select((s) => s.user?.roleType ?? const <String>[]),
  ),
);

/// The spaces they can switch between: Citizen, plus one for each of Venue and
/// Event that they hold the role for.
final Provider<List<AppSpace>> availableSpacesProvider =
    Provider<List<AppSpace>>(
  (ref) => AppSpace.availableTo(ref.watch(heldRolesProvider)),
);

/// The space they are working in, remembered for each account. It is Citizen
/// whenever the saved space is one they no longer hold the role for.
class ActiveSpaceController extends Notifier<AppSpace> {
  static String _key(String? userId) => 'active_space_$userId';

  @override
  AppSpace build() {
    final userId = ref.watch(currentUserIdProvider);
    final roles = ref.watch(heldRolesProvider);
    final saved = AppSpace.fromName(
      userId == null
          ? null
          : ref.read(storageServiceProvider).getString(_key(userId)),
    );
    return saved.isAvailableTo(roles) ? saved : AppSpace.citizen;
  }

  /// Switches space and remembers it.
  Future<void> select(AppSpace space) async {
    if (!space.isAvailableTo(ref.read(heldRolesProvider))) return;
    state = space;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(storageServiceProvider).setString(_key(userId), space.name);
  }
}

final NotifierProvider<ActiveSpaceController, AppSpace> activeSpaceProvider =
    NotifierProvider<ActiveSpaceController, AppSpace>(
  ActiveSpaceController.new,
);
