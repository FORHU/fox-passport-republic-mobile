import 'package:intl/intl.dart';

/// A count in short form for tight rows: 950, 1.2K, 3.4M, in [locale]'s way.
/// Counts under 1,000 are written in full.
String compactCount(int n, {String? locale}) =>
    n < 1000 ? '$n' : NumberFormat.compact(locale: locale).format(n);
