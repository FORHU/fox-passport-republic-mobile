import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';

/// The occasion the person last opened, kept on the device so Home can offer
/// "Continue: birthday". Date and guests are not kept yet.
class LastOccasion extends Notifier<Occasion?> {
  static const _key = 'last_occasion';

  @override
  Occasion? build() =>
      Occasion.fromName(ref.read(storageServiceProvider).getString(_key));

  Future<void> remember(Occasion occasion) async {
    state = occasion;
    await ref.read(storageServiceProvider).setString(_key, occasion.name);
  }
}

final lastOccasionProvider =
    NotifierProvider<LastOccasion, Occasion?>(LastOccasion.new);
