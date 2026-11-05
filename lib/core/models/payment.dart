import 'package:flutter/material.dart';

import 'utility_type.dart';

enum PaymentMethodKind { momo, card }

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    required this.maskedNumber,
    this.isDefault = false,
    this.alwaysFails = false,
  });

  final String id;
  final PaymentMethodKind kind;
  final String label;
  final String maskedNumber;
  final bool isDefault;

  /// Demo-only method that deterministically declines, so the failed
  /// payment experience can be exercised without a backend.
  final bool alwaysFails;

  IconData get icon => kind == PaymentMethodKind.momo
      ? Icons.account_balance_wallet_rounded
      : Icons.credit_card_rounded;
}

/// A package for plan-based utilities (TV bouquets, data bundles, fibre).
class UtilityPlan {
  const UtilityPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  final String id;
  final String name;
  final double price;
  final String description;
}

enum TransactionStatus { success, pending, failed }

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.accountNumber,
    required this.accountNickname,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.paymentMethodLabel,
    this.propertyId,
    this.propertyLabel,
    this.planName,
    this.token,
    this.failureReason,
    this.billerReference,
    this.fee = 0,
  });

  final String id;

  /// Human-facing reference, e.g. TXN-8882-4B.
  final String reference;
  final UtilityType type;
  final String accountNumber;
  final String accountNickname;
  final double amount;
  final double fee;
  final TransactionStatus status;
  final DateTime createdAt;
  final String paymentMethodLabel;
  final String? propertyId;
  final String? propertyLabel;
  final String? planName;

  /// An ECG power token, when the biller returns one. Hubtel credits meters directly.
  final String? token;
  final String? failureReason;

  /// The biller's own receipt number.
  final String? billerReference;

  double get total => amount + fee;
}
