import '../models/models.dart';

/// What the app needs from the GRID API. Live implementations are in
/// `api/live_repositories.dart`.

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

/// Service booking has no API yet, so the app can't take a booking. The
/// booking route shows a "coming soon" screen instead of reaching this.
class UnavailableServicesApi implements ServicesApi {
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
  }) => throw UnsupportedError('Service booking is not available yet.');
}
