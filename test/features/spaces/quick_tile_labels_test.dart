import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// "Add on the web" (14 characters) broke onto a second line with "web" alone
// on a 360-wide phone, while its two neighbours ("Requests", "Gear") stayed on
// one. Three tiles share the width, and the labels are letter-spaced mono, so
// a label of about ten characters is the most one tile holds on a line.
//
// A layout test cannot show this: tests draw with a fallback font, not the
// app's mono one, so everything wraps there. This guards the copy instead.
void main() {
  testWidgets('the provider tile labels are short enough for one line', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(l10n.providerAddOnWeb.length, lessThanOrEqualTo(11));
    expect(l10n.requestsTitle.length, lessThanOrEqualTo(11));
  });
}
