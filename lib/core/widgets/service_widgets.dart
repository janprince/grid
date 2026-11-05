import 'package:flutter/material.dart';

import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../theme/service_art.dart';
import '../utils/formatters.dart';
import 'system.dart';

/// The service's icon on its solid colour. Stands in for a logo in lists.
class ServiceBadge extends StatelessWidget {
  const ServiceBadge({super.key, required this.category, this.size = 44});
  final ServiceCategory category;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: category.label,
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.badge,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(category.icon, color: Colors.white, size: size * 0.5),
    ),
  );
}

/// A service on its tint with the corner arcs — the way a service is shown
/// whenever it is the subject (the services hub, the first booking step).
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.category,
    required this.onTap,
    this.selected,
    this.actionLabel,
  });
  final ServiceCategory category;
  final VoidCallback onTap;

  /// When non-null the card is a choice and shows a radio.
  final bool? selected;

  /// When set, a compact primary button sits at the foot of the card.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: category.label,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: TintCard(
        tint: category.tint,
        arc: category.arc,
        selected: selected ?? false,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ServiceBadge(category: category, size: 46),
                const Spacer(),
                if (selected != null)
                  RadioDot(selected: selected!)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'From ${Fmt.cedis(category.fromPrice)}',
                      style: AppText.caption.copyWith(
                        color: category.ink,
                        fontWeight: FontWeight.w700,
                        fontFeatures: AppText.tabularFigures,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(category.label, style: AppText.title),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: AppText.bodyMuted.copyWith(
                color: category.ink.withValues(alpha: 0.8),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              PrimaryButton(label: actionLabel!, onPressed: onTap),
            ],
          ],
        ),
      ),
    ),
  );
}
