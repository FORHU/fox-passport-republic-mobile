import 'package:flutter_template/shared/photos/photo_picker.dart';

/// Years of experience on a role application (mobile#535, api#423): whole
/// years up to [baseMaxYears], or a claim of more, up to [claimMaxYears],
/// backed by a CV that an admin checks. The API (api#508) and the web
/// (app#441) use the same rules and brackets.
const baseMaxYears = 30;
const claimMaxYears = 50;

/// The highest number the field takes, with or without the claim ticked.
int yearsMax({required bool claiming}) =>
    claiming ? claimMaxYears : baseMaxYears;

/// [raw] as whole years from 0 to [max], or null when it isn't.
int? wholeYears(String raw, int max) {
  final value = raw.trim();
  if (!RegExp(r'^\d{1,2}$').hasMatch(value)) return null;
  final n = int.parse(value);
  return n <= max ? n : null;
}

/// True when [raw] is all digits but over [max], so the field refuses it
/// rather than shows it.
bool exceedsMaxYears(String raw, int max) {
  final value = raw.trim();
  return RegExp(r'^\d+$').hasMatch(value) &&
      (value.length > 2 || int.parse(value) > max);
}

/// The bracket's start for more than 30 years: 31–34 is 30, 35–39 is 35,
/// 40–44 is 40, 45–49 is 45, and 50 is 50. 30 or less comes back as is.
int experienceBracket(int years) {
  if (years <= baseMaxYears) return years;
  if (years >= claimMaxYears) return claimMaxYears;
  return years ~/ 5 * 5;
}

/// A bracket's start as shown: "30+", "35+", "40+", "45+", or "50".
String bracketLabel(int start) => start >= claimMaxYears ? '$start' : '$start+';

/// The CV must be a PDF: the admin reads it in the browser, and the API
/// refuses anything else for a claim.
bool isPdf(PickedPhoto file) => file.name.toLowerCase().endsWith('.pdf');

/// What stops a claim of more than 30 years from being sent.
enum ExperienceClaimProblem {
  /// The years typed are 30 or less (or not a number) with the box ticked.
  tooFewYears,

  /// No CV yet.
  cvMissing,

  /// The CV isn't a PDF.
  cvNotPdf,
}

/// Null when not claiming, or when the claim is complete.
ExperienceClaimProblem? experienceClaimProblem({
  required String experience,
  required bool claiming,
  required PickedPhoto? cv,
}) {
  if (!claiming) return null;
  final years = wholeYears(experience, claimMaxYears);
  if (years == null || years <= baseMaxYears) {
    return ExperienceClaimProblem.tooFewYears;
  }
  if (cv == null) return ExperienceClaimProblem.cvMissing;
  if (!isPdf(cv)) return ExperienceClaimProblem.cvNotPdf;
  return null;
}
