import 'bill_payment.dart';
import 'utility_type.dart';

/// A saved payee: an ECG meter, water account, smartcard or phone number.
class UtilityAccount {
  const UtilityAccount({
    required this.id,
    required this.type,
    required this.accountNumber,
    required this.nickname,
    this.propertyId,
    this.isDefault = false,
    this.lastPaidAt,
    this.dueDate,
    this.lastAmount,
    this.network,
    this.ecgKind,
  });

  final String id;
  final UtilityType type;
  final String accountNumber;
  final String nickname;

  /// Home this account belongs to, if linked.
  final String? propertyId;

  /// Preferred account for this utility type.
  final bool isDefault;
  final DateTime? lastPaidAt;
  final DateTime? dueDate;
  final double? lastAmount;

  /// Airtime and data only: which network to buy from.
  final MobileNetwork? network;

  /// ECG only.
  final EcgKind? ecgKind;

  /// The GRID API product this account is paid with.
  String get productCode => billProductCode(
    type,
    network: network ?? MobileNetwork.guess(accountNumber),
    ecgKind: ecgKind ?? EcgKind.prepaid,
  );

  UtilityAccount copyWith({
    UtilityType? type,
    String? accountNumber,
    String? nickname,
    String? propertyId,
    bool? clearProperty,
    bool? isDefault,
    DateTime? lastPaidAt,
    DateTime? dueDate,
    double? lastAmount,
    MobileNetwork? network,
    EcgKind? ecgKind,
  }) => UtilityAccount(
    id: id,
    type: type ?? this.type,
    accountNumber: accountNumber ?? this.accountNumber,
    nickname: nickname ?? this.nickname,
    propertyId: (clearProperty ?? false)
        ? null
        : (propertyId ?? this.propertyId),
    isDefault: isDefault ?? this.isDefault,
    lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    dueDate: dueDate ?? this.dueDate,
    lastAmount: lastAmount ?? this.lastAmount,
    network: network ?? this.network,
    ecgKind: ecgKind ?? this.ecgKind,
  );
}
