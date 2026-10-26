import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A photo chosen for a post, before it is uploaded.
class PickedMedia {
  const PickedMedia({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Asks the person for photos. An interface so tests need no platform.
abstract class MediaPicker {
  /// Up to [limit] photos; empty when they back out.
  Future<List<PickedMedia>> pickMany(int limit);
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
}

final mediaPickerProvider =
    Provider<MediaPicker>((ref) => GalleryMediaPicker());
