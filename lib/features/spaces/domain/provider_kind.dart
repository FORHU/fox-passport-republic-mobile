import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';

/// What a provider supplies. The Gear and Services spaces share their screens
/// and differ in the thing they list and the requests they answer.
enum ProviderKind {
  gear(AppSpace.gear, RequestKind.asset),
  services(AppSpace.services, RequestKind.service);

  const ProviderKind(this.space, this.request);

  final AppSpace space;

  /// The kind of request for what they supply.
  final RequestKind request;

  bool get isGear => this == gear;

  String get root => space.root;
  String get listings => '$root/listings';
  String get calendar => '$root/calendar';
  String get earnings => '$root/earnings';
  String get more => '$root/more';
  String get requests => '$root/more/requests';
  String get messages => '$root/more/messages';

  /// Events looking for a service to apply to. Services only.
  String get slots => '$root/more/slots';

  /// Where the web adds one.
  String get webAdd =>
      isGear ? '/creator-dashboard/assets' : '/creator-dashboard/services';

  /// Where the web edits one.
  String webEdit(String id) => isGear
      ? '/creator-dashboard/assets/$id'
      : '/creator-dashboard/services/$id/edit';

  /// The kind a space supplies; null for a space that is not a provider's.
  static ProviderKind? of(AppSpace space) {
    for (final kind in values) {
      if (kind.space == space) return kind;
    }
    return null;
  }
}
