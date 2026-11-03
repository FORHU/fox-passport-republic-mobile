import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/domain/home_categories.dart';
import 'package:flutter_template/features/home/presentation/widgets/category_labels.dart';
import 'package:flutter_template/features/occasion/data/packages_repository.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/occasion_colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A photo for an occasion: the first ready-made package of that occasion (in
/// the chosen city) that has one. Null when there is none, and the card then
/// shows the occasion's own colours.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final occasionCoverProvider =
    FutureProvider.autoDispose.family<String?, PackageQuery>(
  (ref, query) async {
    final items = await ref.watch(packagesProvider(query).future);
    for (final item in items) {
      final url = item.imageUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  },
);

/// The occasions as photos: one large card for the first (the one the person
/// last opened, else the most bookable), then a row of smaller ones and the
/// "All" card. Without a photo a card is the occasion's colours with its icon.
class OccasionShowcase extends ConsumerWidget {
  const OccasionShowcase({
    required this.tiles,
    required this.more,
    required this.city,
    required this.continuing,
    required this.onOccasion,
    required this.onAll,
    super.key,
  });

  final List<OccasionTileData> tiles;

  /// How many more categories "All" opens.
  final int more;
  final String? city;

  /// What the person last opened, so the large card can say "Continue".
  final Occasion? continuing;
  final ValueChanged<Occasion> onOccasion;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final featured = tiles.first;

    String? coverOf(Occasion o) =>
        ref.watch(occasionCoverProvider((category: o.name, city: city))).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeaturedCard(
          occasion: featured.occasion,
          label: occasionLabel(l10n, featured.occasion),
          sub: featured.count == null ? null : l10n.homeIdeas(featured.count!),
          pill: continuing == featured.occasion
              ? l10n.homeContinuePlanning
              : l10n.homeStartPlanning,
          photoUrl: coverOf(featured.occasion),
          onTap: () => onOccasion(featured.occasion),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final t in tiles.skip(1)) ...[
                _PhotoCard(
                  occasion: t.occasion,
                  label: occasionLabel(l10n, t.occasion),
                  sub: t.count == null ? null : l10n.homeIdeas(t.count!),
                  photoUrl: coverOf(t.occasion),
                  onTap: () => onOccasion(t.occasion),
                ),
                const SizedBox(width: 12),
              ],
              _AllCard(
                label: l10n.occasionAll,
                sub: more > 0 ? l10n.homeMoreCount(more) : null,
                onTap: onAll,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The occasion's picture, or its colours when it has none.
class _Backdrop extends StatelessWidget {
  const _Backdrop({
    required this.style,
    required this.icon,
    required this.photoUrl,
    required this.height,
  });

  final OccasionStyle style;
  final IconData icon;
  final String? photoUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImageBox(
        url: url,
        width: double.infinity,
        height: height,
      );
    }
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.border, style.background],
        ),
      ),
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(14),
      child: Icon(icon, color: style.icon, size: 26),
    );
  }
}

/// Darkens the bottom of a card so the words on a photo can be read.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.canvas.withValues(alpha: 0.92),
              AppColors.canvas.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.occasion,
    required this.label,
    required this.pill,
    required this.photoUrl,
    required this.onTap,
    this.sub,
  });

  final Occasion occasion;
  final String label;
  final String? sub;
  final String pill;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: sub == null ? '$label, $pill' : '$label, $sub, $pill',
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 176,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _Backdrop(
                    style: occasion.style,
                    icon: occasion.icon,
                    photoUrl: photoUrl,
                    height: 176,
                  ),
                ),
                _Scrim(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.display(size: 22),
                              ),
                              if (sub != null)
                                Text(
                                  sub!,
                                  style: AppTypography.body(
                                    size: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.brPill,
                          ),
                          child: Text(
                            pill,
                            style: AppTypography.display(
                              size: 13,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.occasion,
    required this.label,
    required this.photoUrl,
    required this.onTap,
    this.sub,
  });

  final Occasion occasion;
  final String label;
  final String? sub;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: sub == null ? label : '$label, $sub',
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 128,
            height: 148,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _Backdrop(
                    style: occasion.style,
                    icon: occasion.icon,
                    photoUrl: photoUrl,
                    height: 148,
                  ),
                ),
                _Scrim(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(size: 14),
                        ),
                        if (sub != null)
                          Text(
                            sub!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(
                              size: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllCard extends StatelessWidget {
  const _AllCard({required this.label, required this.onTap, this.sub});

  final String label;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: sub == null ? label : '$label, $sub',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            width: 128,
            height: 148,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.display(size: 14)),
                    if (sub != null)
                      Text(sub!, style: AppTypography.body(size: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
