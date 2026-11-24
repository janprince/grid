// A contract check against a running GRID API: the app's own services code
// books AC servicing, pays, follows the professional, confirms and rates.
// Skipped unless pointed at a development server with the seeded demo
// accounts, fixed OTP codes and simulated service payments:
//
//   flutter test test/live_api_test.dart \
//     --dart-define=GRID_LIVE_API=true \
//     --dart-define=GRID_API_BASE_URL=http://127.0.0.1:8080/api/v1
import 'package:flutter_test/flutter_test.dart';
import 'package:grid/core/data/api/api_client.dart';
import 'package:grid/core/data/api/api_exception.dart';
import 'package:grid/core/data/api/live_repositories.dart';
import 'package:grid/core/data/api/session_store.dart';
import 'package:grid/core/models/models.dart';

const _live = bool.fromEnvironment('GRID_LIVE_API');

/// Keeps the session in memory; the real store needs platform secure storage.
class _Sessions extends SessionStore {
  Session? _session;
  @override
  Session? get current => _session;
  @override
  Future<Session?> load() async => _session;
  @override
  Future<void> save(Session session) async => _session = session;
  @override
  Future<void> clear() async => _session = null;
}

Future<ApiClient> _signIn(String phone) async {
  final sessions = _Sessions();
  final client = ApiClient(sessions);
  final auth = LiveAuthApi(client, sessions);
  // A rerun inside the resend cooldown waits for a fresh code.
  for (var attempt = 0; ; attempt++) {
    try {
      await auth.requestOtp(phone);
      break;
    } on ApiException catch (error) {
      if (error.code != 'auth.otp_rate_limited' || attempt > 15) rethrow;
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
  await auth.verifyOtp(phone, '123456');
  return client;
}

void main() {
  test(
    'a customer books AC servicing, pays, confirms and rates it',
    skip: _live ? false : 'needs a running development API',
    timeout: const Timeout(Duration(minutes: 3)),
    () async {
      final customer = await _signIn('0240000001');
      final provider = await _signIn('0240000003');
      final services = LiveServicesApi(customer);

      // The professional who does AC servicing is online.
      await provider.put<dynamic>(
        '/provider-accounts/me/operating-status',
        body: {'operatingStatus': 'Online'},
      );

      // Earlier runs that stopped half-way leave bookings that would clash.
      for (final old in await services.requests()) {
        if (old.canCancel) {
          await services.cancel(old.id, reason: 'Live contract test cleanup.');
        }
      }

      final catalogue = await services.catalogue();
      final ac = catalogue.bySlug('ac-servicing')!;
      expect(ac.packages, isNotEmpty);
      final general = ac.packages.firstWhere(
        (p) => p.slug == 'ac-servicing-general-service',
      );
      expect(general.price, 250);

      final homes = await customer.get<List<dynamic>>('/properties');
      final home = homes.first as Map<String, dynamic>;

      // Availability only offers hours with someone working nearby.
      final earliest = DateTime.now().add(const Duration(minutes: 70));
      ServiceSlot? slot;
      for (var day = 0; day < 3 && slot == null; day++) {
        final availability = await services.availability(
          serviceId: ac.id,
          propertyId: home['id'] as String,
          date: DateTime.now().add(Duration(days: day)),
        );
        expect(availability.served, isTrue);
        slot = availability.slots
            .where((s) => s.available && s.startsAt.isAfter(earliest))
            .firstOrNull;
      }
      expect(slot, isNotNull, reason: 'no professional working soon');

      final key = 'live-${DateTime.now().microsecondsSinceEpoch}';
      var booking = await services.book(
        lines: [BookingLine(general, 2)],
        propertyId: home['id'] as String,
        scheduledAt: slot!.startsAt,
        idempotencyKey: key,
        notes: 'Two split units, upstairs.',
      );
      expect(booking.total, 500);
      expect(booking.title, contains('General service'));
      expect(booking.payment?.status, ServicePaymentStatus.paid);
      expect(booking.status, ServiceRequestStatus.searching);

      // The same key never books twice.
      final again = await services.book(
        lines: [BookingLine(general, 2)],
        propertyId: home['id'] as String,
        scheduledAt: slot.startsAt,
        idempotencyKey: key,
      );
      expect(again.id, booking.id);

      // The professional accepts and works through every step.
      final offers = (await provider.get<List<dynamic>>(
        '/job-offers',
        query: {'status': 'Pending'},
      )).cast<Map<String, dynamic>>();
      final offer = offers.firstWhere(
        (o) => o['title'] == booking.title && o['price'] == 500,
      );
      expect(offer['earnings'], 425);
      var job = await provider.post<Map<String, dynamic>>(
        '/job-offers/${offer['id']}/accept',
      );

      booking = await services.request(booking.id);
      expect(booking.status, ServiceRequestStatus.assigned);
      expect(booking.provider?.name, isNotEmpty);

      while (job['nextCommand'] != null) {
        job = await provider.post<Map<String, dynamic>>(
          '/jobs/${job['id']}/${job['nextCommand']}',
        );
      }

      booking = await services.request(booking.id);
      expect(booking.awaitingConfirmation, isTrue);

      booking = await services.confirmCompletion(booking.id);
      expect(booking.status, ServiceRequestStatus.completed);
      booking = await services.review(
        booking.id,
        rating: 5,
        comment: 'Both units blowing cold.',
      );
      expect(booking.review?.rating, 5);
      expect(booking.provider?.rating, isNotNull);
      expect(booking.canCancel, isFalse);
    },
  );
}
