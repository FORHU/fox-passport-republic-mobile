import 'package:flutter_template/features/roles/domain/provider_application.dart';
import 'package:flutter_template/features/roles/domain/work_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeWorkLink', () {
    test('adds https:// when it was left off', () {
      expect(
        normalizeWorkLink(' facebook.com/soundgear '),
        'https://facebook.com/soundgear',
      );
      expect(
        normalizeWorkLink('http://soundgear.ph'),
        'http://soundgear.ph',
      );
    });

    test('nothing typed is nothing', () {
      expect(normalizeWorkLink('   '), isNull);
    });
  });

  group('workLinkProblem', () {
    test('a link on its own site is fine, a subdomain too', () {
      expect(
        workLinkProblem(WorkLinkKind.facebook, 'facebook.com/x'),
        isNull,
      );
      expect(
        workLinkProblem(WorkLinkKind.facebook, 'https://m.facebook.com/x'),
        isNull,
      );
      expect(workLinkProblem(WorkLinkKind.youtube, 'youtu.be/abc'), isNull);
      expect(
        workLinkProblem(WorkLinkKind.tiktok, 'tiktok.com/@soundgear'),
        isNull,
      );
    });

    test('a link in the wrong field says so', () {
      expect(
        workLinkProblem(WorkLinkKind.instagram, 'facebook.com/x'),
        WorkLinkProblem.wrongSite,
      );
      // Not fooled by a look-alike host.
      expect(
        workLinkProblem(WorkLinkKind.facebook, 'notfacebook.com/x'),
        WorkLinkProblem.wrongSite,
      );
    });

    test('Website takes any real address', () {
      expect(workLinkProblem(WorkLinkKind.website, 'soundgear.ph'), isNull);
      expect(
        workLinkProblem(WorkLinkKind.website, 'sound gear'),
        WorkLinkProblem.invalid,
      );
      expect(
        workLinkProblem(WorkLinkKind.website, 'ftp://soundgear.ph'),
        WorkLinkProblem.invalid,
      );
    });

    test('an empty field is fine', () {
      expect(workLinkProblem(WorkLinkKind.facebook, ''), isNull);
    });
  });

  group('ProviderApplicationDraft links', () {
    test('sends each filled link once, in field order, as a full address', () {
      const d = ProviderApplicationDraft(
        businessName: 'Sound Gear Co.',
        basedIn: 'Cebu',
        links: {
          WorkLinkKind.website: 'soundgear.ph',
          WorkLinkKind.facebook: 'facebook.com/soundgear',
          WorkLinkKind.instagram: '   ',
        },
      );
      expect(d.portfolioLinks, [
        'https://facebook.com/soundgear',
        'https://soundgear.ph',
      ]);
      expect(d.toData(const {})['portfolioUrls'], d.portfolioLinks);
      expect(d.businessDone, isTrue);
    });

    test('a wrong link holds step 1 back and names its field', () {
      const d = ProviderApplicationDraft(
        businessName: 'Sound Gear Co.',
        basedIn: 'Cebu',
        links: {WorkLinkKind.instagram: 'facebook.com/soundgear'},
      );
      expect(d.linkProblems, {
        WorkLinkKind.instagram: WorkLinkProblem.wrongSite,
      });
      expect(d.businessDone, isFalse);
    });

    test('no links sends no portfolioUrls', () {
      const d = ProviderApplicationDraft(businessName: 'X', basedIn: 'Cebu');
      expect(d.toData(const {}).containsKey('portfolioUrls'), isFalse);
    });
  });
}
