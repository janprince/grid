import 'package:intl/intl.dart';

/// Ghana-centric formatting helpers.
abstract final class Fmt {
  static final NumberFormat _cedis = NumberFormat('#,##0.00');

  /// e.g. `GH₵ 450.00`
  static String cedis(double amount) => 'GH₵ ${_cedis.format(amount)}';

  /// e.g. `24 Oct 2025`
  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);

  /// e.g. `24 Oct 2025 • 2:32 PM`
  static String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy • h:mm a').format(d);

  /// e.g. `2:32 PM`
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  /// Today / Yesterday / 24 Oct
  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    return DateFormat(d.year == now.year ? 'd MMM' : 'd MMM yyyy').format(d);
  }

  /// "Due tomorrow", "Due in 5 days", "Overdue by 2 days"
  static String dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    if (diff < 0) return 'Overdue by ${-diff} day${diff == -1 ? '' : 's'}';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff <= 14) return 'Due in $diff days';
    return 'Due ${date(due)}';
  }

  /// "Last paid 14 days ago"
  static String lastPaidLabel(DateTime paid) {
    final days = DateTime.now().difference(paid).inDays;
    if (days == 0) return 'Paid today';
    if (days == 1) return 'Paid yesterday';
    return 'Last paid $days days ago';
  }

  /// Masks all but the last 4 characters: `•••• 4321`
  static String masked(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }

  /// Formats +233XXXXXXXXX as `+233 55 123 4567`.
  static String ghanaPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    var local = digits;
    if (local.startsWith('233')) local = local.substring(3);
    if (local.startsWith('0')) local = local.substring(1);
    if (local.length != 9) return raw;
    return '+233 ${local.substring(0, 2)} ${local.substring(2, 5)} '
        '${local.substring(5)}';
  }

  /// "45 seconds", "2 minutes" — for rate-limit waits. Null reads as "a minute".
  static String waitTime(int? seconds) {
    if (seconds == null || seconds <= 0) return 'a minute';
    if (seconds < 60) return '$seconds seconds';
    final minutes = (seconds / 60).ceil();
    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }
}
