import 'package:flutter/material.dart';

import '../models/bill_payment.dart';
import '../models/utility_type.dart';

/// Brand identity for each biller GRID pays.
///
/// Before the redesign every utility was the same teal glyph in the same
/// tinted square, so ECG, DStv and MTN were indistinguishable at a glance.
/// Real billers carry real equity — a Ghanaian user recognises MTN yellow
/// and DStv blue instantly — and that recognition is what gives a list of
/// utilities its rhythm.
///
/// This is the single source of truth for biller colour and artwork. It
/// deliberately does *not* restate anything already on [UtilityType]
/// (labels, glyphs, validation); it only adds what the enum has no opinion
/// about.
class BillerBrand {
  const BillerBrand({
    required this.color,
    required this.onColor,
    required this.tint,
    this.asset,
  });

  /// The biller's primary brand colour.
  final Color color;

  /// Legible foreground on [color].
  final Color onColor;

  /// A pale wash of [color] for backgrounds behind the mark.
  final Color tint;

  /// Logo tile under `assets/images/billers/`, or null where the biller is
  /// an aggregate of several networks (airtime and data before a network is
  /// known, when no single mark is correct).
  final String? asset;

  static const _ecgAmber = Color(0xFFF5A623);
  static const _waterBlue = Color(0xFF0B7BC1);
  static const _dstvBlue = Color(0xFF00508F);
  static const _gotvGreen = Color(0xFF018A3A);
  static const _starOrange = Color(0xFFE8500E);
  static const _mtnYellow = Color(0xFFFFCB05);
  static const _telecelRed = Color(0xFFE42528);
  static const _atNavy = Color(0xFF223D76);
  static const _neutralNavy = Color(0xFF13294B);

  static const Map<UtilityType, BillerBrand> _brands = {
    UtilityType.ecg: BillerBrand(
      color: _ecgAmber,
      onColor: Color(0xFF3A2600),
      tint: Color(0xFFFDF0DC),
      asset: 'ecg.webp',
    ),
    UtilityType.water: BillerBrand(
      color: _waterBlue,
      onColor: Colors.white,
      tint: Color(0xFFE0EDF8),
      asset: 'gwcl.webp',
    ),
    UtilityType.dstv: BillerBrand(
      color: _dstvBlue,
      onColor: Colors.white,
      tint: Color(0xFFE2EAF7),
      asset: 'dstv.webp',
    ),
    UtilityType.gotv: BillerBrand(
      color: _gotvGreen,
      onColor: Colors.white,
      tint: Color(0xFFDDF3E7),
      asset: 'gotv.webp',
    ),
    UtilityType.startimes: BillerBrand(
      color: _starOrange,
      onColor: Colors.white,
      tint: Color(0xFFFCE6DC),
      asset: 'startimes.webp',
    ),
    // Airtime and data span MTN, Telecel and AT, so until the network is
    // known they stay neutral rather than borrowing one network's colour.
    UtilityType.airtime: _anyNetwork,
    UtilityType.dataBundle: _anyNetwork,
    UtilityType.internet: _telecel,
  };

  static const _anyNetwork = BillerBrand(
    color: _neutralNavy,
    onColor: Colors.white,
    tint: Color(0xFFE9EDF4),
  );

  static const _mtn = BillerBrand(
    color: _mtnYellow,
    onColor: Color(0xFF3A2F00),
    tint: Color(0xFFFFF6D6),
    asset: 'mtn.webp',
  );

  static const _telecel = BillerBrand(
    color: _telecelRed,
    onColor: Colors.white,
    tint: Color(0xFFFCE4E4),
    asset: 'telecel.webp',
  );

  static const _at = BillerBrand(
    color: _atNavy,
    onColor: Colors.white,
    tint: Color(0xFFE4E9F3),
    asset: 'at.webp',
  );

  static BillerBrand ofNetwork(MobileNetwork network) => switch (network) {
    MobileNetwork.mtn => _mtn,
    MobileNetwork.telecel => _telecel,
    MobileNetwork.airtelTigo => _at,
  };

  /// The network's brand for airtime and data once it's known, otherwise the
  /// utility's own.
  static BillerBrand resolve(UtilityType type, MobileNetwork? network) =>
      type.isPhoneAccount && network != null ? ofNetwork(network) : of(type);

  static BillerBrand of(UtilityType type) => _brands[type]!;

  /// Full asset path, or null when this biller has no single mark.
  String? get assetPath =>
      asset == null ? null : 'assets/images/billers/$asset';
}

extension UtilityBrand on UtilityType {
  BillerBrand get brand => BillerBrand.of(this);
}
