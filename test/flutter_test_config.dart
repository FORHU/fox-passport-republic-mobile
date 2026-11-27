import 'dart:async';

import 'package:visibility_detector/visibility_detector.dart';

/// Runs before every test file. Visibility is reported at once instead of
/// after the detector's usual 500 ms pause, so widget tests that show a post
/// leave no timer behind (the package's advice for tests).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  await testMain();
}
