import 'dart:math';

import 'package:grid/core/data/api/api_exception.dart';
import 'package:grid/core/data/app_prefs.dart';
import 'package:grid/core/data/repositories.dart';
import 'package:grid/core/models/models.dart';

/// In-memory stand-ins for the GRID API, for widget tests only. The app itself
/// always talks to the live API.

const AppUser _user = AppUser(
  id: 'u1',
  name: 'Test Person',
  phone: '+233551234567',
);

const List<Property> _seedProperties = [
  Property(
    id: 'p1',
    nickname: 'My Home',
    area: 'East Legon',
    city: 'Accra',
    address: '45 Test Avenue, East Legon',
    kind: PropertyKind.house,
    isPrimary: true,
  ),
];

final List<UtilityAccount> _seedAccounts = [
  const UtilityAccount(
    id: 'a1',
    type: UtilityType.ecg,
    accountNumber: '14258901334',
    nickname: 'My Home Meter',
    propertyId: 'p1',
    isDefault: true,
  ),
];

final Random _rng = Random();

String _ref(String prefix) => '$prefix-${1000 + _rng.nextInt(9000)}';

class FakeAuthApi implements AuthApi {
  FakeAuthApi(this._prefs);

  final AppPrefs _prefs;

  /// The test OTP, echoed back as [OtpChallenge.developmentCode].
  static const String demoCode = '123456';

  @override
  AppUser? get currentUser => _prefs.loggedIn
      ? AppUser(
          id: _user.id,
          name: _prefs.userName ?? _user.name,
          phone: _prefs.userPhone ?? _user.phone,
          email: _prefs.userEmail,
        )
      : null;

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return OtpChallenge(
      phoneNumber: phoneNumber,
      resendAfterSeconds: 30,
      developmentCode: demoCode,
    );
  }

  @override
  Future<AppUser> verifyOtp(String phoneNumber, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (code != demoCode) {
      throw ApiException(
        code: 'auth.otp_invalid',
        message: 'That code is not correct.',
        statusCode: 400,
      );
    }
    _pendingPhone = phoneNumber;
    // Test sign-ins always walk through profile setup.
    return AppUser(
      id: _user.id,
      name: '',
      phone: phoneNumber,
      profileComplete: false,
    );
  }

  @override
  Future<AppUser> refreshUser() async => currentUser!;

  @override
  Future<AppUser> updateProfile({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    final name = [firstName, ?lastName].join(' ');
    await _prefs.saveSession(
      name: name,
      phone: _pendingPhone ?? _user.phone,
      email: email,
    );
    return currentUser!;
  }

  String? _pendingPhone;

  @override
  Future<void> signOut() => _prefs.clearSession();
}

/// In-memory homes and saved accounts that follow the server's rules
/// (first home is primary, archiving a home unlinks its accounts, one
/// default per utility), like the live API.
class FakeHomeStore implements PropertiesApi {
  final List<Property> _properties = List.of(_seedProperties);
  final List<UtilityAccount> _accounts = List.of(_seedAccounts);

  String _newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';

  // Homes ------------------------------------------------------------------

  @override
  Future<List<Property>> list() async => List.of(_properties);

  @override
  Future<Property> create(Property draft) async {
    final property = Property(
      id: _newId('p'),
      nickname: draft.nickname,
      area: draft.area,
      city: draft.city,
      address: draft.address,
      kind: draft.kind,
      isPrimary: _properties.isEmpty,
      ghanaPostGps: draft.ghanaPostGps,
    );
    _properties.add(property);
    return property;
  }

  @override
  Future<Property> update(Property property) async {
    final index = _properties.indexWhere((p) => p.id == property.id);
    final saved = property.copyWith(isPrimary: _properties[index].isPrimary);
    _properties[index] = saved;
    return saved;
  }

  @override
  Future<void> archive(String id) async {
    final wasPrimary = _properties.any((p) => p.id == id && p.isPrimary);
    _properties.removeWhere((p) => p.id == id);
    for (var i = 0; i < _accounts.length; i++) {
      if (_accounts[i].propertyId == id) {
        _accounts[i] = _accounts[i].copyWith(clearProperty: true);
      }
    }
    if (wasPrimary && _properties.isNotEmpty) {
      await makePrimary(_properties.last.id);
    }
  }

  @override
  Future<void> makePrimary(String id) async {
    for (var i = 0; i < _properties.length; i++) {
      _properties[i] = _properties[i].copyWith(
        isPrimary: _properties[i].id == id,
      );
    }
  }

  // Saved accounts ---------------------------------------------------------

  Future<List<UtilityAccount>> listAccounts() async => List.of(_accounts);

  Future<UtilityAccount> createAccount(UtilityAccount draft) async {
    final hasDefault = _accounts.any(
      (a) => a.type == draft.type && a.isDefault,
    );
    final account = UtilityAccount(
      id: _newId('a'),
      type: draft.type,
      accountNumber: draft.accountNumber,
      nickname: draft.nickname,
      propertyId: draft.propertyId,
      isDefault: draft.isDefault || !hasDefault,
      lastPaidAt: draft.lastPaidAt,
      lastAmount: draft.lastAmount,
    );
    _accounts.add(account);
    if (account.isDefault) _singleDefault(account);
    return account;
  }

  Future<UtilityAccount> updateAccount(UtilityAccount account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    _accounts[index] = account;
    if (account.isDefault) _singleDefault(account);
    return account;
  }

  Future<void> archiveAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index < 0) return;
    final removed = _accounts.removeAt(index);
    if (removed.isDefault) {
      final sameType = _accounts.where((a) => a.type == removed.type);
      if (sameType.isNotEmpty) {
        _singleDefault(sameType.last.copyWith(isDefault: true));
      }
    }
  }

  void _singleDefault(UtilityAccount account) {
    for (var i = 0; i < _accounts.length; i++) {
      final a = _accounts[i];
      if (a.type == account.type) {
        _accounts[i] = a.id == account.id
            ? account
            : a.copyWith(isDefault: false);
      }
    }
  }
}

/// [FakeHomeStore]'s saved-account half, under the [UtilityAccountsApi]
/// method names (the store already uses `list`/`create` for homes).
class FakeUtilityAccountsApi implements UtilityAccountsApi {
  FakeUtilityAccountsApi(this._store);

  final FakeHomeStore _store;

  @override
  Future<List<UtilityAccount>> list() => _store.listAccounts();

  @override
  Future<UtilityAccount> create(UtilityAccount draft) =>
      _store.createAccount(draft);

  @override
  Future<UtilityAccount> update(UtilityAccount account) =>
      _store.updateAccount(account);

  @override
  Future<void> archive(String id) => _store.archiveAccount(id);
}

/// Demo bill payments: every lookup succeeds, and an order is approved and
/// delivered the first time it is read back after being placed.
class FakeBillPaymentsApi implements BillPaymentsApi {
  final Map<String, BillOrder> _orders = {};

  /// An order the server knows about but the app hasn't placed in this test.
  void addFromServer(BillOrder order) => _orders[order.id] = order;
  final Map<String, String> _byKey = {};

  @override
  Future<BillLookup> lookup(BillTarget target) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final type = utilityTypeForProduct(target.productCode);
    return BillLookup(
      productCode: target.productCode,
      accountNumber:
          target.meterNumber ??
          target.accountNumber ??
          target.phoneNumber ??
          '',
      customerName: type.isPhoneAccount ? '' : 'Test Customer',
      nameConfirmed: !type.isPhoneAccount,
      bundles: [
        if (type == UtilityType.dataBundle)
          const BillBundle(value: 'bundle-1', label: '1 GB', amount: 10),
      ],
      fixedPrice: type.isPlanBased,
      minAmount: type.isPlanBased ? null : 1,
      maxAmount: type.isPlanBased
          ? null
          : (type == UtilityType.airtime ? 100 : 1000),
    );
  }

  @override
  Future<BillOrder> placeOrder({
    required BillTarget target,
    required double amount,
    required String idempotencyKey,
    String? bundle,
    String? channel,
    String? savedAccountId,
    String? propertyId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final existing = _byKey[idempotencyKey];
    if (existing != null) return _orders[existing]!;
    final now = DateTime.now();
    final id = 'bo${now.microsecondsSinceEpoch}';
    final order = BillOrder(
      id: id,
      reference: _ref('GRID'),
      productCode: target.productCode,
      accountNumber:
          target.meterNumber ??
          target.accountNumber ??
          target.phoneNumber ??
          '',
      customerName: 'Test Customer',
      principal: amount,
      fee: 0,
      total: amount,
      status: BillOrderStatus.awaitingPayment,
      createdAt: now,
      channel: channel ?? MobileNetwork.mtn.channel,
      awaitingApproval: true,
      maskedPhone: '23355****567',
      savedAccountId: savedAccountId,
      propertyId: propertyId,
    );
    _orders[id] = order;
    _byKey[idempotencyKey] = id;
    return order;
  }

  @override
  Future<BillOrder> order(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final order = _orders[id]!;
    if (order.status != BillOrderStatus.awaitingPayment) return order;
    final now = DateTime.now();
    final settled = BillOrder(
      id: order.id,
      reference: order.reference,
      productCode: order.productCode,
      accountNumber: order.accountNumber,
      customerName: order.customerName,
      principal: order.principal,
      fee: order.fee,
      total: order.total,
      status: BillOrderStatus.completed,
      createdAt: order.createdAt,
      channel: order.channel,
      paidAt: now,
      deliveredAt: now,
      billExternalReference: _ref('BIL'),
      savedAccountId: order.savedAccountId,
      propertyId: order.propertyId,
    );
    return _orders[id] = settled;
  }

  @override
  Future<List<BillOrder>> history() async =>
      _orders.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
