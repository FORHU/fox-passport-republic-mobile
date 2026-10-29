import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// The largest video a post takes, as the API caps it.
const int maxVideoBytes = 100 * 1024 * 1024;

/// A video was chosen that is over [maxVideoBytes].
class MediaTooLarge implements Exception {
  const MediaTooLarge();
}

/// A photo or a video chosen for a post, before it is uploaded.
class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.name,
    this.isVideo = false,
  });

  final Uint8List bytes;
  final String name;
  final bool isVideo;
}

/// Asks the person for photos. An interface so tests need no platform.
abstract class MediaPicker {
  /// Up to [limit] photos; empty when they back out.
  Future<List<PickedMedia>> pickMany(int limit);

  /// One video; null when they back out. Throws [MediaTooLarge] for one
  /// over [maxVideoBytes].
  Future<PickedMedia?> pickVideo();
}

class GalleryMediaPicker implements MediaPicker {
  GalleryMediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedMedia>> pickMany(int limit) async {
    final files = await _picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
      limit: limit,
    );
    return [
      for (final f in files.take(limit))
        PickedMedia(bytes: await f.readAsBytes(), name: f.name),
    ];
  }

  @override
  Future<PickedMedia?> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    // Checked before the bytes are read, so a huge file is never held in
    // memory.
    if (await file.length() > maxVideoBytes) throw const MediaTooLarge();
    return PickedMedia(
      bytes: await file.readAsBytes(),
      name: file.name,
      isVideo: true,
    );
  }
}

final mediaPickerProvider =
    Provider<MediaPicker>((ref) => GalleryMediaPicker());
