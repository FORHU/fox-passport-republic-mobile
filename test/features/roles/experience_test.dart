import 'dart:typed_data';

import 'package:flutter_template/features/roles/domain/experience.dart';
import 'package:flutter_template/features/roles/domain/provider_application.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';

PickedPhoto _file(String name) =>
    PickedPhoto(bytes: Uint8List.fromList([1]), name: name);

/// The same rules as api#508 (`utils/years-of-experience.ts`) and app#441
/// (`experienceBracket.ts`).
void main() {
  test('groups more than 30 years into brackets', () {
    expect(
      {
        for (final y in [12, 30, 31, 34, 35, 39, 40, 44, 45, 49, 50])
          y: experienceBracket(y),
      },
      {
        12: 12,
        30: 30,
        31: 30,
        34: 30,
        35: 35,
        39: 35,
        40: 40,
        44: 40,
        45: 45,
        49: 45,
        50: 50,
      },
    );
    expect(bracketLabel(40), '40+');
    expect(bracketLabel(30), '30+');
    expect(bracketLabel(50), '50');
  });

  test('takes whole years up to the limit', () {
    expect(wholeYears('30', 30), 30);
    expect(wholeYears(' 7 ', 30), 7);
    expect(wholeYears('31', 30), isNull);
    expect(wholeYears('42', 50), 42);
    expect(wholeYears('2.5', 30), isNull);
    expect(wholeYears('', 30), isNull);
    expect(yearsMax(claiming: false), 30);
    expect(yearsMax(claiming: true), 50);
  });

  test('refuses typing that goes over the limit', () {
    expect(exceedsMaxYears('31', 30), isTrue);
    expect(exceedsMaxYears('30', 30), isFalse);
    expect(exceedsMaxYears('51', 50), isTrue);
    expect(exceedsMaxYears('100', 50), isTrue);
    expect(exceedsMaxYears('2.5', 30), isFalse, reason: 'checked, not refused');
  });

  test('a claim needs over 30 years and a PDF CV', () {
    ExperienceClaimProblem? problem(String years, PickedPhoto? cv) =>
        experienceClaimProblem(experience: years, claiming: true, cv: cv);
    expect(problem('30', _file('cv.pdf')), ExperienceClaimProblem.tooFewYears);
    expect(problem('42', null), ExperienceClaimProblem.cvMissing);
    expect(problem('42', _file('cv.docx')), ExperienceClaimProblem.cvNotPdf);
    expect(problem('42', _file('CV.PDF')), isNull);
    expect(
      experienceClaimProblem(experience: '99', claiming: false, cv: null),
      isNull,
      reason: 'not claiming: the field itself refuses it',
    );
  });

  group('drafts', () {
    test('a Provider over 30 years needs the claim and sends the CV', () {
      const base = ProviderApplicationDraft(
        businessName: 'Sound Gear Co.',
        basedIn: 'Cebu City',
        experience: '42',
      );
      expect(base.years, isNull, reason: 'over 30 without the claim');
      expect(base.businessDone, isFalse);

      final claim = base.copyWith(claimingExperience: true);
      expect(claim.years, 42);
      expect(claim.businessDone, isFalse, reason: 'no CV yet');

      final withCv = claim.copyWith(experienceCv: _file('cv.pdf'));
      expect(withCv.businessDone, isTrue);
      expect(withCv.toData(const {})['experience'], 42);
      final form = withCv.toForm(const {});
      expect(form.files.map((f) => f.key), contains(portfolioFileField));

      expect(
        withCv.copyWith(claimingExperience: false).toForm(const {}).files,
        isEmpty,
        reason: 'no claim, no CV sent',
      );
    });

    test('an Event Coordinator claim uses the portfolio file as the CV', () {
      const organizer = RoleApplicationDraft(
        roleType: 'organizer',
        experience: '50',
        claimingExperience: true,
      );
      expect(organizer.years, 50);
      expect(organizer.experienceProblem, ExperienceClaimProblem.cvMissing);
      expect(
        organizer.copyWith(portfolioFile: _file('cv.pdf')).experienceProblem,
        isNull,
      );
      expect(organizer.toData()['experience'], 50);
    });
  });
}
