import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/routing/routes.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/pay_flow_parts.dart';

/// What people come to pay, as they'd name it. TV, airtime and data each
/// cover several billers, so they open a choice of provider first.
enum PayGroup {
  electricity('Electricity', 'ECG prepaid', [UtilityType.ecg]),
  water('Water', 'Ghana Water', [UtilityType.water]),
  tv('TV', '3 providers', [
    UtilityType.dstv,
    UtilityType.gotv,
    UtilityType.startimes,
  ]),
  airtime('Airtime', 'All networks', [UtilityType.airtime]),
  data('Data', 'All networks', [UtilityType.dataBundle]),
  internet('Broadband', 'Telecel', [UtilityType.internet]);

  const PayGroup(this.label, this.caption, this.types);

  final String label;
  final String caption;
  final List<UtilityType> types;

  /// Opens a provider choice before the flow.
  bool get needsChoice => types.length > 1 || types.first.isPhoneAccount;

  String get route =>
      needsChoice ? Routes.payChoose(name) : Routes.payFlow(types.first.name);

  /// The header of the provider choice.
  String get chooseTitle => switch (this) {
    PayGroup.tv => 'TV subscription',
    _ => types.first.flowTitle,
  };

  String get chooseHeading => switch (this) {
    PayGroup.tv => 'Select a TV provider',
    _ => 'Select the recipient\'s network',
  };

  /// The group's mark: one biller's logo, or several fanned out.
  Widget mark({double size = ProviderTile.compactMark}) {
    if (this == PayGroup.tv) {
      return LogoCluster(
        size: size * 0.66,
        marks: [for (final t in types) (s) => BillerMark(t, size: s)],
      );
    }
    if (types.first.isPhoneAccount) {
      return LogoCluster(
        size: size * 0.66,
        marks: [
          for (final n in MobileNetwork.values) (s) => NetworkMark(n, size: s),
        ],
      );
    }
    return BillerMark(types.first, size: size);
  }

  static PayGroup? of(UtilityType type) {
    for (final g in values) {
      if (g.types.contains(type)) return g;
    }
    return null;
  }
}
