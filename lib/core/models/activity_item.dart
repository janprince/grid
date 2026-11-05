import 'package:flutter/material.dart';

import 'payment.dart';
import 'service_request.dart';
import 'utility_type.dart';

enum ActivityKind { payment, service }

/// A unified row for the Activity feed, built from payment transactions
/// and service requests.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.statusLabel,
    this.utilityType,
    this.amount,
    this.propertyLabel,
    this.transaction,
    this.request,
  });

  factory ActivityItem.fromTransaction(PaymentTransaction tx) => ActivityItem(
    id: 'tx-${tx.id}',
    kind: ActivityKind.payment,
    icon: tx.type.icon,
    title: tx.planName == null
        ? tx.type.label
        : '${tx.type.label} • ${tx.planName}',
    subtitle: tx.accountNickname,
    date: tx.createdAt,
    statusLabel: switch (tx.status) {
      TransactionStatus.success => 'Success',
      TransactionStatus.pending => 'Pending',
      TransactionStatus.failed => 'Failed',
    },
    utilityType: tx.type,
    amount: tx.amount,
    propertyLabel: tx.propertyLabel,
    transaction: tx,
  );

  factory ActivityItem.fromRequest(ServiceRequest req) => ActivityItem(
    id: 'req-${req.id}',
    kind: ActivityKind.service,
    icon: req.category.icon,
    title: req.category.label,
    subtitle: req.issue,
    date: req.createdAt,
    statusLabel: req.status.label,
    amount: req.finalAmount,
    propertyLabel: req.propertyLabel,
    request: req,
  );

  final String id;
  final ActivityKind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime date;
  final String statusLabel;

  /// Set for payments, so the row can carry the biller's own mark. Null for
  /// service requests, which are GRID's own dispatch rather than a biller.
  final UtilityType? utilityType;

  final double? amount;
  final String? propertyLabel;
  final PaymentTransaction? transaction;
  final ServiceRequest? request;
}
