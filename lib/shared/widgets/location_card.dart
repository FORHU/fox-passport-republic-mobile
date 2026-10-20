import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/location/map_link.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where a venue or event is, with a button that opens it in Maps.
///
/// [lines] are what to show (a name, an address, a city). The map opens on
/// the pin when [lat] and [lng] are known, else on a search for [query].
/// Draws nothing when there is no place to show.
class LocationCard extends StatelessWidget {
  const LocationCard({
    required this.lines,
    required this.query,
    this.lat,
    this.lng,
    super.key,
  });

  final List<String> lines;
  final String query;
  final double? lat;
  final double? lng;

  Future<void> _open(BuildContext context) async {
    final uri = mapsUri(lat: lat, lng: lng, query: query);
    final message = context.l10n.comingSoonMap;
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line.trim(),
    ];
    if (shown.isEmpty || mapsUri(lat: lat, lng: lng, query: query) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchEventLocation,
            style: AppTypography.display(size: 18),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in shown)
                        Text(line, style: AppTypography.body(size: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _open(context),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(l10n.directionsAction),
                  style: OutlinedButton.styleFrom(
                    // The theme makes buttons full width; a Row cannot hold
                    // that, so size it here.
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.brPill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
