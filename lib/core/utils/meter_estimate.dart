import '../models/utility_account.dart';
import '../models/utility_type.dart';

/// A running estimate of how much prepaid power a home has left.
///
/// GRID has no meter integration yet, so nothing reports a live reading.
/// Rather than invent a stored balance, this derives the estimate from what
/// the app genuinely knows — the size and date of the last top-up — and the
/// UI labels it as an estimate wherever it appears.
///
/// The two constants below are the only assumptions. They are deliberately
/// named and documented so they can be replaced by a tariff lookup and the
/// home's own consumption history once ECG data is wired up.
class MeterEstimate {
  const MeterEstimate({
    required this.unitsBought,
    required this.unitsRemaining,
    required this.daysRemaining,
    required this.fraction,
    required this.lastAmount,
    required this.lastPaidAt,
  });

  /// Average residential end-user tariff, in kWh bought per cedi spent.
  /// ~GH₵1.80 per kWh including levies.
  static const double unitsPerCedi = 0.55;

  /// Typical urban household draw, in kWh per day.
  static const double dailyBurn = 6.0;

  final double unitsBought;
  final double unitsRemaining;
  final int daysRemaining;

  /// Remaining share of the last top-up, in 0..1 — drives the meter fill.
  final double fraction;

  final double lastAmount;
  final DateTime lastPaidAt;

  bool get isEmpty => unitsRemaining <= 0;

  /// Estimate for a prepaid electricity account, or null when this account
  /// is not prepaid power or has never been topped up.
  static MeterEstimate? forAccount(UtilityAccount account, {DateTime? now}) {
    if (account.type != UtilityType.ecg) return null;
    final paidAt = account.lastPaidAt;
    final amount = account.lastAmount;
    if (paidAt == null || amount == null || amount <= 0) return null;

    final at = now ?? DateTime.now();
    final elapsedDays = at.difference(paidAt).inMinutes / (60 * 24);
    if (elapsedDays < 0) return null;

    final bought = amount * unitsPerCedi;
    final burned = elapsedDays * dailyBurn;
    final remaining = (bought - burned).clamp(0.0, bought);

    return MeterEstimate(
      unitsBought: bought,
      unitsRemaining: remaining,
      daysRemaining: (remaining / dailyBurn).floor(),
      fraction: bought == 0 ? 0 : remaining / bought,
      lastAmount: amount,
      lastPaidAt: paidAt,
    );
  }

  /// "about 9 days", "less than a day", "no power left".
  String get daysLabel {
    if (isEmpty) return 'no power left';
    if (daysRemaining < 1) return 'less than a day left';
    if (daysRemaining == 1) return 'about a day left';
    return 'about $daysRemaining days left';
  }
}
