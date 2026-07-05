import 'dart:math';

import '../models/models.dart';
import 'mock_data.dart';

/// Service interfaces for everything that will eventually hit a real
/// backend. The app only talks to these, so swapping the mock
/// implementations for live API clients is a drop-in change.
abstract interface class AuthApi {
  /// Sends an OTP to the given phone/email. Returns the (mock) code hint.
  Future<String> requestOtp(String destination);

  Future<bool> verifyOtp(String destination, String code);
}

abstract interface class PaymentsApi {
  /// Executes a utility payment and returns the resulting transaction.
  Future<PaymentTransaction> pay({
    required UtilityType type,
    required String accountNumber,
    required String accountNickname,
    required double amount,
    required PaymentMethod method,
    String? propertyId,
    String? propertyLabel,
    String? planName,
  });
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
  /// The demo OTP. Shown as a hint on the verification screen.
  static const String demoCode = '123456';

  @override
  Future<String> requestOtp(String destination) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return demoCode;
  }

  @override
  Future<bool> verifyOtp(String destination, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return code == demoCode;
  }
}

class MockPaymentsApi implements PaymentsApi {
  @override
  Future<PaymentTransaction> pay({
    required UtilityType type,
    required String accountNumber,
    required String accountNickname,
    required double amount,
    required PaymentMethod method,
    String? propertyId,
    String? propertyLabel,
    String? planName,
  }) async {
    await Future<void>.delayed(_networkDelay);

    final now = DateTime.now();
    final id = 'tx${now.microsecondsSinceEpoch}';

    if (method.alwaysFails) {
      return PaymentTransaction(
        id: id,
        reference: _ref('TXN'),
        type: type,
        accountNumber: accountNumber,
        accountNickname: accountNickname,
        amount: amount,
        status: TransactionStatus.failed,
        createdAt: now,
        paymentMethodLabel: method.label,
        propertyId: propertyId,
        propertyLabel: propertyLabel,
        planName: planName,
        failureReason:
            'Payment was declined. No money left your account — please try '
            'another payment method.',
      );
    }

    return PaymentTransaction(
      id: id,
      reference: _ref('TXN'),
      type: type,
      accountNumber: accountNumber,
      accountNickname: accountNickname,
      amount: amount,
      status: TransactionStatus.success,
      createdAt: now,
      paymentMethodLabel: method.label,
      propertyId: propertyId,
      propertyLabel: propertyLabel,
      planName: planName,
      token: type == UtilityType.ecg ? _demoToken() : null,
    );
  }

  static String _demoToken() =>
      List.generate(5, (_) => (1000 + _rng.nextInt(9000)).toString()).join(' ');
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
      reference: 'JOB-${3300 + _rng.nextInt(600)}',
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

/// Static lookups that a live backend would eventually serve.
abstract final class CatalogRepository {
  static List<UtilityPlan> plansFor(UtilityType type) =>
      MockData.plans[type] ?? const [];

  static List<PaymentMethod> get paymentMethods => MockData.paymentMethods;
}
