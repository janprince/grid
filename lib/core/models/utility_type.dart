import 'package:flutter/material.dart';

/// Every utility GRID can pay for. UI metadata lives here so the generic
/// payment flow, pay hub and saved-accounts screens all stay in sync.
enum UtilityType {
  ecg(
    label: 'ECG Prepaid',
    shortLabel: 'Buy ECG',
    providerName: 'Electricity Company of Ghana',
    tagline: 'Prepaid electricity top-up',
    icon: Icons.bolt_rounded,
    accountLabel: 'Meter number',
    accountHint: 'e.g. 14258901334',
    minDigits: 10,
    maxDigits: 13,
    quickAmounts: [50, 100, 200, 500],
  ),
  water(
    label: 'Ghana Water',
    shortLabel: 'Pay Water',
    providerName: 'Ghana Water Company Ltd',
    tagline: 'Water bill payment',
    icon: Icons.water_drop_rounded,
    accountLabel: 'Account number',
    accountHint: 'e.g. 040123456',
    minDigits: 8,
    maxDigits: 12,
    quickAmounts: [40, 80, 150, 300],
  ),
  dstv(
    label: 'DStv',
    shortLabel: 'Pay TV',
    providerName: 'MultiChoice Ghana',
    tagline: 'TV subscription renewal',
    icon: Icons.live_tv_rounded,
    accountLabel: 'Smartcard number',
    accountHint: 'e.g. 7024561890',
    minDigits: 10,
    maxDigits: 11,
    isPlanBased: true,
  ),
  gotv(
    label: 'GOtv',
    shortLabel: 'GOtv',
    providerName: 'MultiChoice Ghana',
    tagline: 'TV subscription renewal',
    icon: Icons.tv_rounded,
    accountLabel: 'IUC number',
    accountHint: 'e.g. 2019845672',
    minDigits: 10,
    maxDigits: 11,
    isPlanBased: true,
  ),
  startimes(
    label: 'StarTimes',
    shortLabel: 'StarTimes',
    providerName: 'StarTimes Ghana',
    tagline: 'TV subscription renewal',
    icon: Icons.connected_tv_rounded,
    accountLabel: 'Smartcard number',
    accountHint: 'e.g. 02501234567',
    minDigits: 10,
    maxDigits: 12,
    isPlanBased: true,
  ),
  airtime(
    label: 'Airtime',
    shortLabel: 'Airtime',
    providerName: 'MTN • Telecel • AT',
    tagline: 'Top up any network',
    icon: Icons.smartphone_rounded,
    accountLabel: 'Phone number',
    accountHint: 'e.g. 055 123 4567',
    minDigits: 9,
    maxDigits: 12,
    isPhoneAccount: true,
    quickAmounts: [10, 20, 50, 100],
  ),
  dataBundle(
    label: 'Data Bundle',
    shortLabel: 'Data',
    providerName: 'MTN • Telecel • AT',
    tagline: 'Internet data bundles',
    icon: Icons.signal_cellular_alt_rounded,
    accountLabel: 'Phone number',
    accountHint: 'e.g. 055 123 4567',
    minDigits: 9,
    maxDigits: 12,
    isPhoneAccount: true,
    isPlanBased: true,
  ),
  internet(
    label: 'Internet / Fibre',
    shortLabel: 'Internet',
    providerName: 'Surfline • MTN Fibre • Telecel Broadband',
    tagline: 'Broadband renewal',
    icon: Icons.wifi_rounded,
    accountLabel: 'Account ID',
    accountHint: 'e.g. 88012345',
    minDigits: 6,
    maxDigits: 12,
    isPlanBased: true,
  );

  const UtilityType({
    required this.label,
    required this.shortLabel,
    required this.providerName,
    required this.tagline,
    required this.icon,
    required this.accountLabel,
    required this.accountHint,
    required this.minDigits,
    required this.maxDigits,
    this.isPlanBased = false,
    this.isPhoneAccount = false,
    this.quickAmounts = const [],
  });

  final String label;
  final String shortLabel;
  final String providerName;
  final String tagline;
  final IconData icon;
  final String accountLabel;
  final String accountHint;
  final int minDigits;
  final int maxDigits;

  /// Plan-based utilities (TV, data, internet) pick a package;
  /// the rest enter an amount.
  final bool isPlanBased;

  /// Airtime/data are keyed to a phone number, not a meter/account.
  final bool isPhoneAccount;
  final List<int> quickAmounts;

  bool get isTv =>
      this == UtilityType.dstv ||
      this == UtilityType.gotv ||
      this == UtilityType.startimes;
}
