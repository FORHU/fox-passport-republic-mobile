import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A photo the user chose to send.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Where a photo comes from.
enum PhotoSource { gallery, camera }

/// Why a photo could not be taken.
enum PhotoPickFailure {
  /// The user refused (or has switched off) camera access.
  cameraDenied,

  /// The device has no usable camera.
  cameraUnavailable,

  /// Anything else the platform reported.
  other,
}

/// The outcome of [PhotoCapture.take]. A result rather than a thrown error, so
/// the screens that ask never need a `try/catch`.
sealed class PhotoPickResult {
  const PhotoPickResult();
}

class PhotoPicked extends PhotoPickResult {
  const PhotoPicked(this.photo);

  final PickedPhoto photo;
}

/// The user backed out; nothing to report.
class PhotoPickCancelled extends PhotoPickResult {
  const PhotoPickCancelled();
}

class PhotoPickFailed extends PhotoPickResult {
  const PhotoPickFailed(this.reason);

  final PhotoPickFailure reason;
}

/// Asks the user for a photo. An interface so tests need no platform.
abstract class PhotoPicker {
  /// Null when the user backs out.
  Future<PickedPhoto?> pick();
}

/// A picker that can return several photos at once. Separate from
/// [PhotoPicker] so a screen that wants one photo, and the fakes that stand in
/// for it, are unaffected.
abstract class MultiPhotoPicker {
  /// Up to [limit] photos from the gallery; empty when the user backs out.
  Future<List<PickedPhoto>> pickMany({required int limit});
}

/// Takes a photo from the camera or the gallery, for the screens that need
/// the choice and a plain answer when the camera is refused (the role
/// applications' documents and selfie).
abstract class PhotoCapture {
  /// A photo from [source]. [frontCamera] asks the camera for the selfie
  /// lens; it only matters for [PhotoSource.camera].
  Future<PhotoPickResult> take({
    required PhotoSource source,
    bool frontCamera = false,
  });
}

class DevicePhotoPicker implements PhotoPicker, PhotoCapture, MultiPhotoPicker {
  DevicePhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedPhoto>> pickMany({required int limit}) async {
    // The platform needs at least two to offer a multiple choice.
    if (limit < 2) {
      final one = await pick();
      return [if (one != null) one];
    }
    final files = await _picker.pickMultiImage(
      limit: limit,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return [
      for (final file in files.take(limit))
        PickedPhoto(bytes: await file.readAsBytes(), name: file.name),
    ];
  }

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

  @override
  Future<PhotoPickResult> take({
    required PhotoSource source,
    bool frontCamera = false,
  }) async {
    try {
      final camera = source == PhotoSource.camera;
      final file = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        // An ID has small print: more resolution than a chat photo.
        maxWidth: camera ? 2000 : 1600,
        imageQuality: 85,
        preferredCameraDevice:
            frontCamera ? CameraDevice.front : CameraDevice.rear,
      );
      if (file == null) return const PhotoPickCancelled();
      return PhotoPicked(
        PickedPhoto(bytes: await file.readAsBytes(), name: file.name),
      );
    } on PlatformException catch (e) {
      return PhotoPickFailed(failureFor(e.code));
    }
  }

  /// Maps a platform error code to a reason. image_picker reports a refused
  /// camera as `camera_access_denied` and a missing one as
  /// `no_available_camera`.
  static PhotoPickFailure failureFor(String code) {
    if (code.contains('denied') || code.contains('restricted')) {
      return PhotoPickFailure.cameraDenied;
    }
    if (code.contains('no_available_camera')) {
      return PhotoPickFailure.cameraUnavailable;
    }
    return PhotoPickFailure.other;
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => DevicePhotoPicker());

final photoCaptureProvider = Provider<PhotoCapture>(
  (ref) => DevicePhotoPicker(),
);
