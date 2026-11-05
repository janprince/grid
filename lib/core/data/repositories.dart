import 'dart:math';

import '../models/models.dart';
import 'api/api_exception.dart';
import 'app_prefs.dart';
import 'mock_data.dart';

/// Service interfaces for everything that will eventually hit a real
/// backend. The app only talks to these, so swapping the mock
/// implementations for live API clients is a drop-in change.

/// What GRID said when asked to text a sign-in code.
class OtpChallenge {
  const OtpChallenge({
    required this.phoneNumber,
    required this.resendAfterSeconds,
    this.developmentCode,
  });

  /// The number as the server normalised it (`233XXXXXXXXX`).
  final String phoneNumber;
  final int resendAfterSeconds;

  /// Echoed only by a development server (and the mock), so testing can skip SMS.
  final String? developmentCode;
}

/// Phone + OTP sign-in and the signed-in person's profile.
///
/// Failures are thrown as [ApiException] in both implementations, so screens
/// branch on the same `error.code` values either way.
abstract interface class AuthApi {
  /// The person signed in on this device, restored synchronously at launch.
  AppUser? get currentUser;

  Future<OtpChallenge> requestOtp(String phoneNumber);

  /// Signs in. The returned user's [AppUser.profileComplete] says whether
  /// they still need to tell GRID their name.
  Future<AppUser> verifyOtp(String phoneNumber, String code);

  /// Re-reads the profile from the server.
  Future<AppUser> refreshUser();

  Future<AppUser> updateProfile({
    required String firstName,
    String? lastName,
    String? email,
  });

  Future<void> signOut();
}

/// The signed-in person's homes. The server owns which one is primary.
abstract interface class PropertiesApi {
  Future<List<Property>> list();

  /// Creates a home. [Property.id] and [Property.isPrimary] are ignored.
  Future<Property> create(Property draft);

  Future<Property> update(Property property);

  /// Archives the home; its saved accounts become unlinked.
  Future<void> archive(String id);

  Future<void> makePrimary(String id);
}

/// Saved meters, smartcards and phone numbers.
abstract interface class UtilityAccountsApi {
  Future<List<UtilityAccount>> list();

  /// Creates an account. The first one of its utility becomes the default.
  Future<UtilityAccount> create(UtilityAccount draft);

  Future<UtilityAccount> update(UtilityAccount account);

  Future<void> archive(String id);
}

/// Bill payments: look a bill up, place an order (which prompts the
/// customer's own MoMo wallet), then read the order until it settles.
abstract interface class BillPaymentsApi {
  /// What the biller knows about the account. Stores nothing. Throws
  /// [MeterSelectionRequired] when an ECG phone has several meters.
  Future<BillLookup> lookup(BillTarget target);

  /// Places the order and sends the MoMo prompt. Reusing [idempotencyKey]
  /// returns the same order instead of prompting again.
  Future<BillOrder> placeOrder({
    required BillTarget target,
    required double amount,
    required String idempotencyKey,
    String? bundle,
    String? channel,
    String? savedAccountId,
    String? propertyId,
  });

  Future<BillOrder> order(String id);

  /// The signed-in person's orders, newest first.
  Future<List<BillOrder>> history();
}

/// An ECG phone lookup found several meters; ask which one and look up again.
class MeterSelectionRequired implements Exception {
  const MeterSelectionRequired(this.meters);

  final List<MeterChoice> meters;
}

abstract interface class ServicesApi {
  Future<ServiceRequest> submitRequest({
    required ServiceCategory category,
    required String issue,
    required String description,
    required Property property,
    required ServiceUrgency urgency,
    required DateTime preferredDate,
    required String timeSlot,
    required int photoCount,
  });
}

// ---------------------------------------------------------------------------
// Mock implementations (demo mode — no real money moves, nothing is
// dispatched). Simulated latency keeps the UX honest.
// ---------------------------------------------------------------------------

const Duration _networkDelay = Duration(milliseconds: 1600);
final Random _rng = Random();

String _ref(String prefix) {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  final digits = 1000 + _rng.nextInt(9000);
  final suffix =
      '${chars[_rng.nextInt(chars.length)]}${chars[_rng.nextInt(chars.length)]}';
  return '$prefix-$digits-$suffix';
}

class MockAuthApi implements AuthApi {
  MockAuthApi(this._prefs);

  final AppPrefs _prefs;

  /// The demo OTP, echoed back as [OtpChallenge.developmentCode].
  static const String demoCode = '123456';

  @override
  AppUser? get currentUser => _prefs.loggedIn
      ? AppUser(
          id: MockData.user.id,
          name: _prefs.userName ?? MockData.user.name,
          phone: _prefs.userPhone ?? MockData.user.phone,
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
    // Demo sign-ins always walk through profile setup.
    return AppUser(
      id: MockData.user.id,
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
      phone: _pendingPhone ?? MockData.user.phone,
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
/// default per utility), so demo mode behaves like the live app.
class MockHomeStore implements PropertiesApi {
  final List<Property> _properties = List.of(MockData.properties);
  final List<UtilityAccount> _accounts = List.of(MockData.accounts);

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

/// [MockHomeStore]'s saved-account half, under the [UtilityAccountsApi]
/// method names (the store already uses `list`/`create` for homes).
class MockUtilityAccountsApi implements UtilityAccountsApi {
  MockUtilityAccountsApi(this._store);

  final MockHomeStore _store;

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
class MockBillPaymentsApi implements BillPaymentsApi {
  final Map<String, BillOrder> _orders = {};
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
      customerName: type.isPhoneAccount ? '' : 'GRID Demo Customer',
      nameConfirmed: !type.isPhoneAccount,
      bundles: [
        if (type == UtilityType.dataBundle)
          for (final plan in CatalogRepository.plansFor(type))
            BillBundle(value: plan.id, label: plan.name, amount: plan.price),
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
      customerName: 'GRID Demo Customer',
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

class MockServicesApi implements ServicesApi {
  @override
  Future<ServiceRequest> submitRequest({
    required ServiceCategory category,
    required String issue,
    required String description,
    required Property property,
    required ServiceUrgency urgency,
    required DateTime preferredDate,
    required String timeSlot,
    required int photoCount,
  }) async {
    await Future<void>.delayed(_networkDelay);

    final now = DateTime.now();
    return ServiceRequest(
      id: 'sr${now.microsecondsSinceEpoch}',
      reference: 'GJ-${3300 + _rng.nextInt(600)}',
      category: category,
      issue: issue,
      description: description,
      propertyId: property.id,
      propertyLabel: property.nickname,
      urgency: urgency,
      preferredDate: preferredDate,
      timeSlot: timeSlot,
      status: ServiceRequestStatus.pending,
      createdAt: now,
      photoCount: photoCount,
      timeline: [
        TimelineEvent(
          title: 'Request submitted',
          subtitle: 'We are finding you a vetted professional.',
          time: now,
        ),
      ],
    );
  }
}

/// Static demo catalogue. Live data bundles come from the bill lookup.
abstract final class CatalogRepository {
  static List<UtilityPlan> plansFor(UtilityType type) =>
      MockData.plans[type] ?? const [];

  static List<PaymentMethod> get paymentMethods => MockData.paymentMethods;
}
