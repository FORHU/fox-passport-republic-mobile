import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// The formats a portfolio or resume may be (app#371): PDF and Word. The API
/// checks the file's bytes too and has the final word.
const portfolioExtensions = <String>['pdf', 'doc', 'docx'];

/// The largest portfolio the API takes.
const int maxPortfolioBytes = 15 * 1024 * 1024;

/// Why a document could not be used.
enum DocumentPickFailure {
  /// Not a PDF or Word file (a picker's filter is only a hint on some
  /// devices).
  unsupported,

  /// Over [maxPortfolioBytes].
  tooLarge,

  /// Anything else the platform reported.
  other,
}

/// The outcome of [DocumentPicker.pick]. A result rather than a thrown error,
/// so the screens that ask never need a `try/catch`.
sealed class DocumentPickResult {
  const DocumentPickResult();
}

/// The chosen file, as bytes and a name like any other picked file.
class DocumentPicked extends DocumentPickResult {
  const DocumentPicked(this.file);

  final PickedPhoto file;
}

/// The user backed out; nothing to report.
class DocumentPickCancelled extends DocumentPickResult {
  const DocumentPickCancelled();
}

class DocumentPickFailed extends DocumentPickResult {
  const DocumentPickFailed(this.reason);

  final DocumentPickFailure reason;
}

/// Whether a file by this name is one a portfolio may be.
bool isPortfolioFileName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0) return false;
  return portfolioExtensions.contains(name.substring(dot + 1).toLowerCase());
}

/// Asks the user for a portfolio or resume. An interface so tests need no
/// platform.
abstract class DocumentPicker {
  Future<DocumentPickResult> pick();
}

class DeviceDocumentPicker implements DocumentPicker {
  @override
  Future<DocumentPickResult> pick() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: portfolioExtensions,
      );
      if (file == null) return const DocumentPickCancelled();
      if (!isPortfolioFileName(file.name)) {
        return const DocumentPickFailed(DocumentPickFailure.unsupported);
      }
      final size = await file.length();
      if (size != null && size > maxPortfolioBytes) {
        return const DocumentPickFailed(DocumentPickFailure.tooLarge);
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxPortfolioBytes) {
        return const DocumentPickFailed(DocumentPickFailure.tooLarge);
      }
      return DocumentPicked(PickedPhoto(bytes: bytes, name: file.name));
    } on PlatformException {
      return const DocumentPickFailed(DocumentPickFailure.other);
    }
  }
}

final documentPickerProvider = Provider<DocumentPicker>(
  (ref) => DeviceDocumentPicker(),
);
