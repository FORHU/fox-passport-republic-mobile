import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Makes the player for one video. A provider so a test can hand the page a
/// fake that plays nothing.
typedef ReelPlayerFactory = VideoPlayerController Function(String url);

final reelPlayerFactoryProvider = Provider<ReelPlayerFactory>(
  (ref) => (url) => VideoPlayerController.networkUrl(
        Uri.parse(url),
        // Sound from another app keeps playing under a muted clip.
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      ),
);
