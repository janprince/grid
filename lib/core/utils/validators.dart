import '../models/utility_type.dart';

/// Local form validation for Ghana-specific inputs.
abstract final class Validators {
  /// Accepts `0XXXXXXXXX`, `XXXXXXXXX` or `+233XXXXXXXXX`.
  static String? ghanaPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    var local = digits;
    if (local.startsWith('233')) local = local.substring(3);
    if (local.startsWith('0')) local = local.substring(1);
    if (local.length != 9) {
      return 'Enter a valid Ghana phone number';
    }
    return null;
  }

  /// Normalises any accepted phone input to `+233XXXXXXXXX`.
  static String normalizePhone(String value) {
    var local = value.replaceAll(RegExp(r'\D'), '');
    if (local.startsWith('233')) local = local.substring(3);
    if (local.startsWith('0')) local = local.substring(1);
    return '+233$local';
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? notEmpty(String? value, {String label = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  /// Digits-only account references (meter numbers, smartcards, etc.).
  static String? digits(
    String? value, {
    required int min,
    required int max,
    required String label,
  }) {
    final v = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (v.isEmpty) return '$label is required';
    if (!RegExp(r'^\d+$').hasMatch(v)) return '$label must contain digits only';
    if (v.length < min || v.length > max) {
      return min == max
          ? '$label must be $min digits'
          : '$label must be $min–$max digits';
    }
    return null;
  }

  /// The account number for [type]: a Ghana phone for airtime and data,
  /// letters and digits for ECG meters, digits for everything else.
  static String? account(String? value, UtilityType type) {
    if (type.isPhoneAccount) return ghanaPhone(value);
    if (!type.allowsLetters) {
      return digits(
        value,
        min: type.minDigits,
        max: type.maxDigits,
        label: type.accountLabel,
      );
    }
    final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return '${type.accountLabel} is required';
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(v)) {
      return '${type.accountLabel} can only contain letters and digits';
    }
    if (v.length < type.minDigits || v.length > type.maxDigits) {
      return '${type.accountLabel} must be ${type.minDigits}–${type.maxDigits} characters';
    }
    return null;
  }

  static String? amount(String? value, {double min = 1, double max = 10000}) {
    final v = double.tryParse((value ?? '').replaceAll(',', ''));
    if (v == null) return 'Enter a valid amount';
    if (v < min) return 'Minimum amount is GH₵ ${min.toStringAsFixed(0)}';
    if (v > max) return 'Maximum amount is GH₵ ${max.toStringAsFixed(0)}';
    return null;
  }

  static String? otp(String? value) {
    if ((value ?? '').replaceAll(RegExp(r'\D'), '').length != 6) {
      return 'Enter the 6-digit code';
    }
    return null;
  }
}
