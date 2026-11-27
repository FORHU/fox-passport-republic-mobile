import 'package:flutter_template/l10n/generated/app_localizations.dart';

/// How far a venue serves, narrowest first, as the API's `VenueCoverage`
/// (mobile#498). It replaces the radius a venue used to draw.
const venueCoverageAreas = [
  'local',
  'municipal',
  'city',
  'province',
  'national',
  'international',
];

/// The area's name, e.g. "City-wide"; the code itself if unknown.
String coverageAreaLabel(AppLocalizations l10n, String code) => switch (code) {
      'local' => l10n.coverageLocal,
      'municipal' => l10n.coverageMunicipal,
      'city' => l10n.coverageCity,
      'province' => l10n.coverageProvince,
      'national' => l10n.coverageNational,
      'international' => l10n.coverageInternational,
      _ => code,
    };

/// What the area means, e.g. "Available throughout the city."
String coverageAreaHint(AppLocalizations l10n, String code) => switch (code) {
      'local' => l10n.coverageLocalHint,
      'municipal' => l10n.coverageMunicipalHint,
      'city' => l10n.coverageCityHint,
      'province' => l10n.coverageProvinceHint,
      'national' => l10n.coverageNationalHint,
      'international' => l10n.coverageInternationalHint,
      _ => '',
    };
