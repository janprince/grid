import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';

/// A bundle split into what people compare: how much data, and the rest of
/// the telco's name for it ("Chat Monthly · 2 GB" → "2 GB", "Chat Monthly").
class BundleFacts {
  BundleFacts._(this.size, this.name, this.group);

  factory BundleFacts.of(BillBundle bundle) {
    final label = clean(bundle.label);
    final match = _size.firstMatch(label) ?? _size.firstMatch(bundle.value);
    final size = match?.group(0)?.replaceAll(' ', '').toUpperCase();
    final name = match == null
        ? ''
        : label
              .replaceFirst(match.group(0)!, ' ')
              .replaceAll(RegExp(r'\s{2,}'), ' ')
              .replaceAll(RegExp(r'^[\s·\-|,]+|[\s·\-|,]+$'), '')
              .replaceAll(RegExp(r'\s+[\-·|]\s+[\-·|]\s+'), ' · ');
    return BundleFacts._(size ?? label, name, _groupOf(label));
  }

  /// The telco's name without what the app shows elsewhere or nobody
  /// needs: a price in brackets ("(GHs 0.5)"), and an internal code after a
  /// dot ("· DATANVSTRDLY"). The API strips these too; this keeps an older
  /// server's labels readable.
  static String clean(String label) => label
      .replaceAll(
        RegExp(r'\(\s*(?:GH[S₵C]?|GH¢|₵)\s*[\d.,]+\s*\)', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'\s*·\s*[A-Z0-9_]{6,}\s*$'), '')
      .replaceAll(RegExp(r'\s+,'), ',')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  /// One line for receipts and the confirm sheet: "22.29MB · No Expiry".
  String get summary => name.isEmpty ? size : '$size · $name';

  /// "2GB", or the whole label when it names no size.
  final String size;

  /// What the telco calls it, without the size; may be empty.
  final String name;

  /// Which filter it falls under, e.g. "Monthly".
  final String group;

  static final _size = RegExp(
    r'\d+(?:[.,]\d+)?\s?(?:GB|MB|TB)',
    caseSensitive: false,
  );

  static String _groupOf(String label) {
    final l = label.toLowerCase();
    if (RegExp(r'no.?expir|non.?expir|flexi').hasMatch(l)) return 'No expiry';
    if (RegExp(r'daily|day|24 ?h').hasMatch(l)) return 'Daily';
    if (RegExp(r'week').hasMatch(l)) return 'Weekly';
    if (RegExp(r'month|30 ?days').hasMatch(l)) return 'Monthly';
    if (RegExp(r'night|midnight|kokrokoo|dawn').hasMatch(l)) return 'Night';
    return 'Other';
  }
}

/// The telco's bundles as a two-column grid of cards, with filters across the
/// top when the bundles fall into more than one kind.
class BundleGrid extends StatefulWidget {
  const BundleGrid({
    super.key,
    required this.bundles,
    required this.selected,
    required this.onSelected,
  });

  final List<BillBundle> bundles;
  final BillBundle? selected;
  final ValueChanged<BillBundle> onSelected;

  @override
  State<BundleGrid> createState() => _BundleGridState();
}

class _BundleGridState extends State<BundleGrid> {
  static const _all = 'All';
  static const _order = [
    'No expiry',
    'Daily',
    'Weekly',
    'Monthly',
    'Night',
    'Other',
  ];

  String _filter = _all;

  @override
  Widget build(BuildContext context) {
    final facts = {for (final b in widget.bundles) b: BundleFacts.of(b)};
    final groups = _order
        .where((g) => facts.values.any((f) => f.group == g))
        .toList();
    final shown = _filter == _all
        ? widget.bundles
        : widget.bundles.where((b) => facts[b]!.group == _filter).toList();

    final rows = <Widget>[];
    for (var i = 0; i < shown.length; i += 2) {
      if (i > 0) rows.add(Gaps.md);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + 2; j++) ...[
                if (j > i) Gaps.md,
                Expanded(
                  child: j < shown.length
                      ? _BundleCard(
                          facts: facts[shown[j]]!,
                          price: shown[j].amount,
                          selected: widget.selected == shown[j],
                          onTap: () => widget.onSelected(shown[j]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groups.length > 1) ...[
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: groups.length + 1,
              separatorBuilder: (_, _) => Gaps.sm,
              itemBuilder: (context, i) {
                final group = i == 0 ? _all : groups[i - 1];
                return _FilterChip(
                  label: group,
                  selected: _filter == group,
                  onTap: () => setState(() => _filter = group),
                );
              },
            ),
          ),
          Gaps.lg,
        ],
        ...rows,
      ],
    );
  }
}

/// Outlined, not filled, when chosen: on this screen the bundles are the
/// content and the filter should stay quiet.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: Corners.smRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navySoft : AppColors.surface,
          borderRadius: Corners.smRadius,
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.lineStrong,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppText.subtitle.copyWith(
            fontSize: 13.5,
            color: selected ? AppColors.navy : AppColors.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({
    required this.facts,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final BundleFacts facts;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: [
      facts.size,
      if (facts.name.isNotEmpty) facts.name,
      Fmt.cedis(price),
    ].join(', '),
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Corners.lgRadius,
          boxShadow: AppColors.raisedShadow,
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.surface,
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                facts.size,
                maxLines: 1,
                style: AppText.title.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  fontFeatures: AppText.tabularFigures,
                ),
              ),
            ),
            if (facts.name.isNotEmpty) ...[
              Gaps.xs,
              Text(
                facts.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 12.5),
              ),
            ],
            const Spacer(),
            Gaps.sm,
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                Fmt.cedis(price),
                style: AppText.subtitle.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppText.tabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
