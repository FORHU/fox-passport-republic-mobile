import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';

/// Reads the signed-in user's passport.
class PassportRepository {
  PassportRepository(this._api);

  final ApiService _api;

  /// The citizen's passport. Sample data is reserved for explicit mock mode.
  Future<PassportSummary> load() async {
    final body = await _api.get(ApiEndpoints.passportMe);
    final data = _data(body);
    if (data == null) {
      if (AppConfig.instance.useMock) return PassportSummary.sample();
      throw const FormatException('Passport response is missing data');
    }

    final paths = [
      for (final p in (data['paths'] as List? ?? const []))
        if (p is Map) p.cast<String, dynamic>(),
    ];
    final totalXp = paths.fold<int>(
      0,
      (best, p) {
        final xp = (p['totalXP'] as num?)?.toInt() ?? 0;
        return xp > best ? xp : best;
      },
    );

    final stamps = [
      for (final s in (data['stamps'] as List? ?? const []))
        if (s is Map) _stamp(s.cast<String, dynamic>()),
    ];
    final earned = <String, Map<String, dynamic>>{
      for (final ub in (data['userBadges'] as List? ?? const []))
        if (ub is Map && ub['badge'] is Map)
          '${(ub['badge'] as Map)['id']}':
              (ub['badge'] as Map).cast<String, dynamic>(),
    };

    final catalogue = await _catalogue();
    final badges = <PassportBadge>[
      for (final b in earned.values) _badge(b, earned: true),
      for (final b in catalogue)
        if (!earned.containsKey('${b['id']}')) _badge(b, earned: false),
    ];

    if (totalXp == 0 && stamps.isEmpty && earned.isEmpty) {
      if (AppConfig.instance.useMock) return PassportSummary.sample();
    }
    return PassportSummary.fromTotalXp(
      totalXp: totalXp,
      stamps: stamps,
      badges: badges,
    );
  }

  Future<List<Map<String, dynamic>>> _catalogue() async {
    final body = await _api.get(ApiEndpoints.passportBadges);
    final list = body is Map ? body['data'] : body;
    if (list is! List) {
      if (AppConfig.instance.useMock) return const [];
      throw const FormatException('Badge catalogue response is not a list');
    }
    return [
      for (final b in list)
        if (b is Map) b.cast<String, dynamic>(),
    ];
  }

  static Map<String, dynamic>? _data(Object? body) {
    final data = body is Map ? body['data'] : null;
    return data is Map ? data.cast<String, dynamic>() : null;
  }

  static PassportStamp _stamp(Map<String, dynamic> s) {
    final place = (s['location'] ?? s['eventName'] ?? '?').toString();
    final letters = place.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase();
    return PassportStamp(
      label: letters.length >= 3 ? letters.substring(0, 3) : letters,
      date: DateTime.tryParse('${s['eventDate']}')?.toLocal(),
    );
  }

  static PassportBadge _badge(Map<String, dynamic> b, {required bool earned}) =>
      PassportBadge(
        id: '${b['id']}',
        name: (b['name'] ?? '').toString(),
        earned: earned,
        colorHex: b['color'] as String?,
      );
}

final passportRepositoryProvider = Provider<PassportRepository>(
  (ref) => PassportRepository(ref.watch(apiServiceProvider)),
);

final FutureProvider<PassportSummary> passportProvider =
    FutureProvider.autoDispose<PassportSummary>(
  (ref) => ref.watch(passportRepositoryProvider).load(),
);
