import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// Bottom sheet listing saved homes; the whole app pivots on the
/// selection made here.
Future<void> showPropertySwitcher(BuildContext context) {
  return showAppBottomSheet(
    context,
    title: 'Switch home',
    child: const _PropertySwitcherList(),
  );
}

class _PropertySwitcherList extends ConsumerWidget {
  const _PropertySwitcherList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final selectedId = ref.watch(selectedPropertyIdProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final property in properties) ...[
          SelectionTile(
            selected: property.id == selectedId,
            onTap: () {
              ref.read(selectedPropertyIdProvider.notifier).select(property.id);
              Navigator.of(context).pop();
            },
            title: property.nickname,
            subtitle: property.location,
            leading: TintedIcon(
              property.id == selectedId
                  ? Icons.home_rounded
                  : Icons.home_outlined,
            ),
            trailing: property.isPrimary
                ? const StatusBadge(label: 'Primary', tone: BadgeTone.success)
                : null,
          ),
          Gaps.md,
        ],
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(Routes.addProperty);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: AppColors.teal,
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add a new home'),
        ),
      ],
    );
  }
}
