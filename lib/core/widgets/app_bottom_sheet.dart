import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Standard GRID modal bottom sheet with title and safe-area padding.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: Insets.xl,
        right: Insets.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Insets.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Gaps.lg,
          Flexible(child: child),
        ],
      ),
    ),
  );
}
