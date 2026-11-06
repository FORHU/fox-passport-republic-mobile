import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What XP and Coins are, in plain words. Static: it says only what is true in
/// the app today, so it changes when ranks, achievements and the rest arrive.
class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = [
      (Icons.bolt_rounded, l10n.howItWorksXpTitle, l10n.howItWorksXpBody),
      (
        Icons.toll_rounded,
        l10n.howItWorksCoinsTitle,
        l10n.howItWorksCoinsBody,
      ),
      (Icons.flag_outlined, l10n.howItWorksEarnTitle, l10n.howItWorksEarnBody),
      (
        Icons.card_giftcard_rounded,
        l10n.howItWorksSpendTitle,
        l10n.howItWorksSpendBody,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          l10n.howItWorksTitle,
          style: AppTypography.display(size: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            l10n.howItWorksIntro,
            style: AppTypography.body(),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, body) in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InfoCard(icon: icon, title: title, body: body),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.display()),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.body(size: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
