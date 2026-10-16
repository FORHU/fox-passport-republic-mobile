import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens take colours from `AppColors`, so a palette change is one edit and
/// nothing drifts. This fails when a raw colour sneaks back into a screen.
void main() {
  test('no screen or widget hard-codes a colour', () {
    final raw = RegExp(
      r'(?<![A-Za-z])Color\(0x|(?<![A-Za-z])Colors\.'
      '(white|black|red|green|blue|grey|orange|amber|yellow|purple|pink|cyan)',
    );
    // Parsing a colour the API sends is not choosing one.
    const allowed = {
      'lib/features/passport/presentation/pages/passport_page.dart',
    };

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/theme/') || allowed.contains(path)) continue;
      if (path.startsWith('lib/l10n/generated/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(line)) offenders.add('$path:${i + 1}  ${line.trim()}');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
