import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/citizens/citizen_widgets.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// The other social accounts a person can link from their profile. The key is
/// what the API calls it.
enum SocialPlatform {
  instagram('instagram', 'Instagram', Icons.camera_alt_outlined),
  facebook('facebook', 'Facebook', Icons.facebook),
  tiktok('tiktok', 'TikTok', Icons.music_note_rounded),
  x('x', 'X', Icons.alternate_email_rounded),
  youtube('youtube', 'YouTube', Icons.play_circle_outline_rounded),
  website('website', 'Website', Icons.language_rounded);

  const SocialPlatform(this.key, this.label, this.icon);

  final String key;

  /// A brand name, the same in every language.
  final String label;
  final IconData icon;
}

/// The links the API sent, keyed by platform. Anything that is not a known
/// platform or an `http(s)` address is dropped, so a bad row cannot put a
/// strange link on someone's profile.
Map<SocialPlatform, String> parseSocialLinks(Object? json) {
  if (json is! Map) return const {};
  final links = <SocialPlatform, String>{};
  for (final platform in SocialPlatform.values) {
    final value = json[platform.key];
    if (value is! String) continue;
    final uri = Uri.tryParse(value.trim());
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      links[platform] = value.trim();
    }
  }
  return links;
}

/// A row of tappable links to a person's other accounts. Each opens in its own
/// app or the browser.
class CitizenSocialLinks extends StatelessWidget {
  const CitizenSocialLinks({required this.links, super.key});

  final Map<SocialPlatform, String> links;

  Future<void> _open(BuildContext context, String link) async {
    final failed = context.l10n.citizenLinkFailed;
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) showTopToast(context, failed);
  }

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in links.entries)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _open(context, entry.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.key.icon,
                    size: 13 * context.fit,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    entry.key.label,
                    style: citizenTiny(
                      context,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
