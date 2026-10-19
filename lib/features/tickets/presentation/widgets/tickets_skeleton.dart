import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/skeleton.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';

/// Ticket-shaped placeholders for the Upcoming and Past lists while they load:
/// the status and name, the date / doors / guests row, and the QR square.
class TicketsSkeleton extends StatelessWidget {
  const TicketsSkeleton({this.count = 2, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            const _TicketShape(),
          ],
        ],
      ),
    );
  }
}

/// Card-shaped placeholders for the Match requests list while it loads.
class RequestsSkeleton extends StatelessWidget {
  const RequestsSkeleton({this.count = 2, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            const _RequestShape(),
          ],
        ],
      ),
    );
  }
}

class _TicketShape extends StatelessWidget {
  const _TicketShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 80, height: 12),
          SizedBox(height: 12),
          SkeletonBox(width: 200, height: 24),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 34)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 34)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 34)),
            ],
          ),
          SizedBox(height: 20),
          Center(child: SkeletonBox(width: 148, height: 148)),
        ],
      ),
    );
  }
}

class _RequestShape extends StatelessWidget {
  const _RequestShape();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 12),
          SizedBox(height: 12),
          SkeletonBox(width: 220, height: 20),
          SizedBox(height: 16),
          SkeletonBox(height: 44),
        ],
      ),
    );
  }
}
