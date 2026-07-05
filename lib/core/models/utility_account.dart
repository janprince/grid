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
  );
}
