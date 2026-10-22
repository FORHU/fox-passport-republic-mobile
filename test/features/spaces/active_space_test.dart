import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Session extends AuthController {
  _Session(this.roles, {this.id = 'u1'});

  final List<String> roles;
  final String id;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: id,
          email: '$id@example.com',
          name: 'Ada',
          roleType: roles,
        ),
      );
}

void main() {
  Future<ProviderContainer> container({
    required List<String> roles,
    Map<String, Object> saved = const {},
    String id = 'u1',
  }) async {
    SharedPreferences.setMockInitialValues(saved);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => _Session(roles, id: id)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a Citizen with no role has nowhere to switch to', () async {
    final c = await container(roles: const []);

    expect(c.read(availableSpacesProvider), [AppSpace.citizen]);
    expect(c.read(activeSpaceProvider), AppSpace.citizen);
  });

  test('starts in the space they were last working in', () async {
    final c = await container(
      roles: const ['venueFoxer'],
      saved: {'active_space_u1': 'venue'},
    );

    expect(c.read(activeSpaceProvider), AppSpace.venue);
  });

  test('switching is remembered', () async {
    final c = await container(roles: const ['venueFoxer', 'eventFoxer']);

    await c.read(activeSpaceProvider.notifier).select(AppSpace.event);

    expect(c.read(activeSpaceProvider), AppSpace.event);
    expect(
      (await SharedPreferences.getInstance()).getString('active_space_u1'),
      'event',
    );
  });

  test('a space they no longer hold the role for falls back to Citizen',
      () async {
    final c = await container(
      roles: const ['eventFoxer'],
      saved: {'active_space_u1': 'venue'},
    );

    expect(c.read(activeSpaceProvider), AppSpace.citizen);
  });

  test('cannot switch into a space without the role', () async {
    final c = await container(roles: const ['eventFoxer']);

    await c.read(activeSpaceProvider.notifier).select(AppSpace.venue);

    expect(c.read(activeSpaceProvider), AppSpace.citizen);
    expect(
      (await SharedPreferences.getInstance()).getString('active_space_u1'),
      isNull,
    );
  });

  test('each account remembers its own space', () async {
    final c = await container(
      roles: const ['venueFoxer'],
      id: 'u2',
      saved: {'active_space_u1': 'venue'},
    );

    // u2 never chose one, whatever u1 did on this phone.
    expect(c.read(activeSpaceProvider), AppSpace.citizen);
  });
}
