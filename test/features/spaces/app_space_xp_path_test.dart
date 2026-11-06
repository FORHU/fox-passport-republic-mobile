import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('xpPath', () {
    test('each space works its own role path', () {
      expect(AppSpace.citizen.xpPath(const []), 'user');
      expect(AppSpace.venue.xpPath(const ['venueFoxer']), 'venueFoxer');
      expect(AppSpace.event.xpPath(const ['eventFoxer']), 'eventFoxer');
      expect(AppSpace.gear.xpPath(const ['gearFoxer']), 'gearFoxer');
      expect(AppSpace.organizer.xpPath(const ['organizer']), 'organizer');
    });

    test('Services is the service path for a Talent', () {
      expect(
        AppSpace.services.xpPath(const ['serviceFoxer']),
        'serviceFoxer',
      );
    });

    test('Services is the performer path for a Performer who is not a Talent',
        () {
      expect(
        AppSpace.services.xpPath(const ['performerFoxer']),
        'performerFoxer',
      );
    });

    test('someone who is both a Performer and a Talent works the service path',
        () {
      expect(
        AppSpace.services.xpPath(const ['performerFoxer', 'serviceFoxer']),
        'serviceFoxer',
      );
    });

    test('the merged provider role works the service path', () {
      expect(
        AppSpace.services.xpPath(const ['providerFoxer', 'performerFoxer']),
        'serviceFoxer',
      );
    });
  });
}
