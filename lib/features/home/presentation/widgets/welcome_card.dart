import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/helpers.dart';
import 'package:flutter_template/shared/widgets/app_card.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.edgeInsetsMd,
      child: AppCard(
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            AppSpacing.md.v,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Helpers.greeting()},',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
