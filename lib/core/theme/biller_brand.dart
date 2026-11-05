import 'package:flutter/material.dart';

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

  /// Logo file under `assets/images/billers/`, or null where the biller is
  /// an aggregate of several networks (airtime and data span MTN, Telecel
  /// and AT, so no single mark is correct).
  final String? asset;

  static const _ecgAmber = Color(0xFFF5A623);
  static const _waterBlue = Color(0xFF0B7BC1);
  static const _dstvBlue = Color(0xFF0B4EA2);
  static const _gotvGreen = Color(0xFF00A14B);
  static const _starOrange = Color(0xFFE8500E);
  static const _mtnYellow = Color(0xFFFFCB05);
  static const _fibreViolet = Color(0xFF6C4BC1);

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
      asset: 'gwcl.png',
    ),
    UtilityType.dstv: BillerBrand(
      color: _dstvBlue,
      onColor: Colors.white,
      tint: Color(0xFFE2EAF7),
      asset: 'dstv.png',
    ),
    UtilityType.gotv: BillerBrand(
      color: _gotvGreen,
      onColor: Colors.white,
      tint: Color(0xFFDDF3E7),
      asset: 'gotv.png',
    ),
    UtilityType.startimes: BillerBrand(
      color: _starOrange,
      onColor: Colors.white,
      tint: Color(0xFFFCE6DC),
      asset: 'startimes.png',
    ),
    // Airtime and data span MTN, Telecel and AT — no single mark applies,
    // so these use the network-neutral yellow with the enum's own glyph.
    UtilityType.airtime: BillerBrand(
      color: _mtnYellow,
      onColor: Color(0xFF3A2F00),
      tint: Color(0xFFFFF6D6),
    ),
    UtilityType.dataBundle: BillerBrand(
      color: _mtnYellow,
      onColor: Color(0xFF3A2F00),
      tint: Color(0xFFFFF6D6),
    ),
    UtilityType.internet: BillerBrand(
      color: _fibreViolet,
      onColor: Colors.white,
      tint: Color(0xFFEBE5F8),
      asset: 'surfline.png',
    ),
  };

  static BillerBrand of(UtilityType type) => _brands[type]!;

  /// Full asset path, or null when this biller has no single mark.
  String? get assetPath =>
      asset == null ? null : 'assets/images/billers/$asset';
}

extension UtilityBrand on UtilityType {
  BillerBrand get brand => BillerBrand.of(this);
}
