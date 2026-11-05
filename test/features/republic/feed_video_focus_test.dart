import 'package:flutter_template/features/republic/data/feed_video_focus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FeedVideoFocus focus;

  setUp(() => focus = FeedVideoFocus());
  tearDown(() => focus.dispose());

  test('nothing plays until a video is mostly on screen', () {
    focus.report('a', 0.3);
    expect(focus.value, isNull);

    focus.report('a', 0.7);
    expect(focus.value, 'a');
  });

  test('the video that is playing keeps the turn while it is on screen', () {
    focus
      ..report('a', 0.7)
      ..report('b', 1);
    expect(focus.value, 'a');
  });

  test('when it leaves, the most visible one takes over', () {
    focus
      ..report('a', 0.7)
      ..report('b', 0.8)
      ..report('c', 1)
      ..report('a', 0.1);
    expect(focus.value, 'c');
  });

  test('releasing the playing video hands over, or stops', () {
    focus
      ..report('a', 1)
      ..report('b', 0.7)
      ..release('a');
    expect(focus.value, 'b');

    focus.release('b');
    expect(focus.value, isNull);
  });

  test('nothing plays while suspended, and it picks again after', () {
    focus
      ..report('a', 1)
      ..suspend(true);
    expect(focus.value, isNull);

    focus.suspend(false);
    expect(focus.value, 'a');
  });

  test('sound is off at first', () {
    expect(focus.muted.value, isTrue);
  });
}
