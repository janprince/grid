import 'package:flutter/material.dart';

import 'service_category.dart';
import 'utility_type.dart';

enum ReminderSeverity { info, warning, urgent }

/// An upcoming deadline for a home: a bill about to expire or
/// maintenance that is due.
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dueDate,
    required this.severity,
    this.utilityType,
    this.serviceCategory,
    this.propertyId,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime dueDate;
  final ReminderSeverity severity;

  /// Set when the reminder resolves to a payment flow.
  final UtilityType? utilityType;

  /// Set when the reminder resolves to a service booking.
  final ServiceCategory? serviceCategory;
  final String? propertyId;
  final String? actionLabel;

  IconData get icon =>
      utilityType?.icon ??
      serviceCategory?.icon ??
      Icons.notifications_active_rounded;
}
