import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A photo the user chose to send.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Asks the user for a photo. An interface so tests need no platform.
abstract class PhotoPicker {
  /// Null when the user backs out.
  Future<PickedPhoto?> pick();
}

class GalleryPhotoPicker implements PhotoPicker {
  GalleryPhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPhoto?> pick() async {
    // Downscaled: chat photos do not need full camera resolution.
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedPhoto(bytes: await file.readAsBytes(), name: file.name);
  }
}

final photoPickerProvider =
    Provider<PhotoPicker>((ref) => GalleryPhotoPicker());
