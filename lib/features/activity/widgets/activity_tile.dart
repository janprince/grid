import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';

/// One row of history: a payment or a service request, as a [HistoryRow].
///
/// The biller's own mark (or the service's art) carries the row; the words
/// say what it was and when, and the right side says how much and how it
/// ended, in plain words rather than a pill.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.item,
    required this.onTap,
    this.timeOnly = false,
    this.divider = true,
  });

  final ActivityItem item;
  final VoidCallback onTap;

  /// Under a date header the day is already said; show the time instead.
  final bool timeOnly;
  final bool divider;

  /// Whose account it was. A payment saved under no nickname falls back to
  /// its type's name, which the title already says; show the number then.
  String _who() {
    final tx = item.transaction;
    if (tx != null &&
        (item.subtitle.isEmpty || item.subtitle == tx.type.label)) {
      return tx.type.isPhoneAccount
          ? Fmt.ghanaPhone(tx.accountNumber)
          : Fmt.masked(tx.accountNumber);
    }
    return item.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final when = timeOnly ? Fmt.time(item.date) : Fmt.relativeDay(item.date);
    final (status, tone) = switch (item) {
      ActivityItem(transaction: final tx?) => switch (tx.status) {
        TransactionStatus.success => ('Completed', HistoryTone.quiet),
        TransactionStatus.pending => ('Pending', HistoryTone.waiting),
        TransactionStatus.failed => ('Failed', HistoryTone.problem),
      },
      ActivityItem(request: final req?) => (
        req.status.label,
        switch (req.status) {
          ServiceRequestStatus.awaitingPayment ||
          ServiceRequestStatus.searching => HistoryTone.waiting,
          ServiceRequestStatus.assigned ||
          ServiceRequestStatus.inProgress => HistoryTone.active,
          ServiceRequestStatus.paymentFailed => HistoryTone.problem,
          _ => HistoryTone.quiet,
        },
      ),
      _ => (item.statusLabel, HistoryTone.quiet),
    };

    return HistoryRow(
      leading: item.utilityType != null
          ? BillerMark(
              item.utilityType!,
              size: 48,
              network: item.transaction?.network,
            )
          : item.request != null
          ? ServiceBadge(slug: item.request!.serviceSlug, size: 48)
          : HistoryIcon(item.icon),
      title: item.title,
      subtitle: '${_who()} · $when',
      value: item.amount == null ? null : Fmt.cedis(item.amount!),
      status: status,
      tone: tone,
      onTap: onTap,
      divider: divider,
    );
  }
}
