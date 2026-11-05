import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/api/api_config.dart';
import '../data/api/live_repositories.dart';
import '../data/api/session_store.dart';
import '../data/app_prefs.dart';
import '../data/mock_data.dart';
import '../data/repositories.dart';
import '../models/models.dart';

/// Overridden in main() with the real instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final appPrefsProvider = Provider<AppPrefs>(
  (ref) => AppPrefs(ref.watch(sharedPrefsProvider)),
);

/// Whether the app talks to the GRID API. Tests and offline demos run on mock
/// data: `--dart-define=GRID_USE_API=false`.
final apiEnabledProvider = Provider<bool>((ref) => ApiConfig.useApi);

/// Overridden in main() with an instance whose session is already loaded, so
/// the first route can be decided synchronously.
final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(sessionStoreProvider)),
);

/// Demo-mode homes and saved accounts, shared so their rules can see each other.
final _mockHomeStoreProvider = Provider<MockHomeStore>(
  (ref) => MockHomeStore(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => ref.watch(apiEnabledProvider)
      ? LiveAuthApi(
          ref.watch(apiClientProvider),
          ref.watch(sessionStoreProvider),
        )
      : MockAuthApi(ref.watch(appPrefsProvider)),
);

final propertiesApiProvider = Provider<PropertiesApi>(
  (ref) => ref.watch(apiEnabledProvider)
      ? LivePropertiesApi(ref.watch(apiClientProvider))
      : ref.watch(_mockHomeStoreProvider),
);

final utilityAccountsApiProvider = Provider<UtilityAccountsApi>(
  (ref) => ref.watch(apiEnabledProvider)
      ? LiveUtilityAccountsApi(ref.watch(apiClientProvider))
      : MockUtilityAccountsApi(ref.watch(_mockHomeStoreProvider)),
);

final billPaymentsApiProvider = Provider<BillPaymentsApi>(
  (ref) => ref.watch(apiEnabledProvider)
      ? LiveBillPaymentsApi(ref.watch(apiClientProvider))
      : MockBillPaymentsApi(),
);
final servicesApiProvider = Provider<ServicesApi>((ref) => MockServicesApi());

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

/// [needsProfile]: signed in, but has not told GRID their name yet.
enum AuthStatus { needsOnboarding, loggedOut, needsProfile, loggedIn }

class SessionState {
  const SessionState({required this.status, this.user});

  final AuthStatus status;
  final AppUser? user;
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    if (ref.watch(apiEnabledProvider)) {
      // A refresh token the server rejects ends the session everywhere.
      ref.watch(apiClientProvider).onSessionExpired = () =>
          state = const SessionState(status: AuthStatus.loggedOut);
    }
    if (!ref.watch(appPrefsProvider).onboardingDone) {
      return const SessionState(status: AuthStatus.needsOnboarding);
    }
    final user = ref.watch(authApiProvider).currentUser;
    if (user != null && user.profileComplete) {
      // Pick up profile changes made from another device.
      Future.microtask(_refreshUser);
    }
    return _stateFor(user);
  }

  static SessionState _stateFor(AppUser? user) => switch (user) {
    null => const SessionState(status: AuthStatus.loggedOut),
    AppUser(profileComplete: false) => SessionState(
      status: AuthStatus.needsProfile,
      user: user,
    ),
    _ => SessionState(status: AuthStatus.loggedIn, user: user),
  };

  Future<void> _refreshUser() async {
    try {
      final user = await ref.read(authApiProvider).refreshUser();
      if (state.user?.id == user.id) state = _stateFor(user);
    } on Object {
      // Offline or expired: keep the cached profile; expiry is handled by the client.
    }
  }

  Future<void> completeOnboarding() async {
    await ref.read(appPrefsProvider).setOnboardingDone();
    state = _stateFor(ref.read(authApiProvider).currentUser);
  }

  /// Verifies the code; the router then moves on to profile setup or home.
  Future<void> verifyOtp(String phoneNumber, String code) async {
    final user = await ref.read(authApiProvider).verifyOtp(phoneNumber, code);
    state = _stateFor(user);
  }

  Future<void> completeProfile({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    final user = await ref
        .read(authApiProvider)
        .updateProfile(firstName: firstName, lastName: lastName, email: email);
    state = _stateFor(user);
  }

  Future<void> signOut() async {
    await ref.read(authApiProvider).signOut();
    state = const SessionState(status: AuthStatus.loggedOut);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// The signed-in person's id, or null. Home data reloads when it changes.
final _signedInUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  return session.status == AuthStatus.loggedIn ? session.user?.id : null;
});

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

/// A server-owned list cached for the UI. Every change goes to the API and
/// is followed by a reload, because the server also moves defaults and
/// unlinks accounts as side effects.
abstract class _ServerListNotifier<T> extends Notifier<List<T>> {
  /// Bumped on every build so a reload for a previous user is discarded.
  int _generation = 0;

  Future<List<T>> fetch();

  @override
  List<T> build() {
    final generation = ++_generation;
    final userId = ref.watch(_signedInUserIdProvider);
    if (userId == null) return const [];
    Future.microtask(() => _reload(generation));
    return const [];
  }

  Future<void> refresh() => _reload(_generation);

  Future<void> _reload(int generation) async {
    try {
      final items = await fetch();
      if (generation == _generation && ref.mounted) {
        state = items;
        onLoaded();
      }
    } on Object catch (error) {
      debugPrint('Could not load ${T.toString()} list: $error');
      if (generation == _generation && ref.mounted) onLoaded();
    }
  }

  void onLoaded() {}
}

class PropertiesNotifier extends _ServerListNotifier<Property> {
  PropertiesApi get _api => ref.read(propertiesApiProvider);

  @override
  Future<List<Property>> fetch() => _api.list();

  @override
  void onLoaded() => ref.read(homesLoadedProvider.notifier).markLoaded();

  /// Saves a new home; returns it as stored.
  Future<Property> add(Property draft, {bool makePrimary = false}) async {
    final created = await _api.create(draft);
    if (makePrimary && !created.isPrimary) await _api.makePrimary(created.id);
    await refresh();
    return created;
  }

  Future<void> save(Property property, {bool makePrimary = false}) async {
    await _api.update(property);
    if (makePrimary && !property.isPrimary) {
      await _api.makePrimary(property.id);
    }
    await refresh();
  }

  Future<void> remove(String id) async {
    await _api.archive(id);
    if (ref.read(selectedPropertyIdProvider) == id) {
      ref.read(selectedPropertyIdProvider.notifier).select(null);
    }
    await refresh();
    // Accounts linked to it were unlinked by the archive.
    await ref.read(accountsProvider.notifier).refresh();
  }

  Future<void> setPrimary(String id) async {
    await _api.makePrimary(id);
    await refresh();
  }
}

final propertiesProvider = NotifierProvider<PropertiesNotifier, List<Property>>(
  PropertiesNotifier.new,
);

/// False until the signed-in person's homes have been fetched once, so the
/// dashboard can tell "loading" apart from "no homes yet".
class HomesLoadedNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(_signedInUserIdProvider);
    return false;
  }

  void markLoaded() => state = true;
}

final homesLoadedProvider = NotifierProvider<HomesLoadedNotifier, bool>(
  HomesLoadedNotifier.new,
);

/// The home the person picked in the switcher; null means "the primary one".
class SelectedPropertyIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(_signedInUserIdProvider);
    return null;
  }

  void select(String? id) => state = id;
}

final selectedPropertyIdProvider =
    NotifierProvider<SelectedPropertyIdNotifier, String?>(
      SelectedPropertyIdNotifier.new,
    );

final selectedPropertyProvider = Provider<Property?>((ref) {
  final id = ref.watch(selectedPropertyIdProvider);
  final properties = ref.watch(propertiesProvider);
  if (properties.isEmpty) return null;
  for (final p in properties) {
    if (p.id == id) return p;
  }
  return properties.firstWhere(
    (p) => p.isPrimary,
    orElse: () => properties.first,
  );
});

final propertyByIdProvider = Provider.family<Property?, String?>((ref, id) {
  if (id == null) return null;
  final properties = ref.watch(propertiesProvider);
  for (final p in properties) {
    if (p.id == id) return p;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Utility accounts
// ---------------------------------------------------------------------------

class AccountsNotifier extends _ServerListNotifier<UtilityAccount> {
  UtilityAccountsApi get _api => ref.read(utilityAccountsApiProvider);

  @override
  Future<List<UtilityAccount>> fetch() => _api.list();

  Future<UtilityAccount> add(UtilityAccount draft) async {
    final created = await _api.create(draft);
    await refresh();
    return created;
  }

  Future<void> save(UtilityAccount account) async {
    await _api.update(account);
    await refresh();
  }

  Future<void> remove(String id) async {
    await _api.archive(id);
    await refresh();
  }

  /// Shows a payment on a saved account straight away. The live server works
  /// this out itself; the next reload replaces it with the server's figure.
  void markPaid(String id, double amount) {
    state = [
      for (final a in state)
        a.id == id
            ? a.copyWith(lastPaidAt: DateTime.now(), lastAmount: amount)
            : a,
    ];
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<UtilityAccount>>(
      AccountsNotifier.new,
    );

final accountsByTypeProvider =
    Provider.family<List<UtilityAccount>, UtilityType>((ref, type) {
      final accounts = ref.watch(accountsProvider);
      final filtered = accounts.where((a) => a.type == type).toList()
        ..sort((a, b) {
          if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
          return a.nickname.compareTo(b.nickname);
        });
      return filtered;
    });

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------

/// Bill payment history, read from the orders API. Demo mode adds the
/// bundled sample transactions underneath.
class TransactionsNotifier extends _ServerListNotifier<PaymentTransaction> {
  @override
  Future<List<PaymentTransaction>> fetch() async {
    final orders = await ref.read(billPaymentsApiProvider).history();
    final live = [for (final order in orders) _describe(order)];
    return ref.read(apiEnabledProvider)
        ? live
        : [...live, ...MockData.transactions];
  }

  /// The order as a transaction, named the way the person saved it.
  PaymentTransaction _describe(BillOrder order) {
    final saved = ref
        .read(accountsProvider)
        .where((a) => a.id == order.savedAccountId)
        .firstOrNull;
    return order.toTransaction(
      nickname: saved?.nickname,
      propertyLabel: ref.read(propertyByIdProvider(order.propertyId))?.nickname,
    );
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<PaymentTransaction>>(
      TransactionsNotifier.new,
    );

// ---------------------------------------------------------------------------
// Service requests
// ---------------------------------------------------------------------------

class ServiceRequestsNotifier extends Notifier<List<ServiceRequest>> {
  @override
  List<ServiceRequest> build() => List.of(MockData.serviceRequests);

  void insert(ServiceRequest request) => state = [request, ...state];

  void cancel(String id) {
    state = [
      for (final r in state)
        r.id == id
            ? r.copyWith(
                status: ServiceRequestStatus.cancelled,
                timeline: [
                  ...r.timeline,
                  TimelineEvent(
                    title: 'Request cancelled',
                    subtitle: 'You cancelled this request.',
                    time: DateTime.now(),
                  ),
                ],
              )
            : r,
    ];
  }
}

final serviceRequestsProvider =
    NotifierProvider<ServiceRequestsNotifier, List<ServiceRequest>>(
      ServiceRequestsNotifier.new,
    );

final serviceRequestByIdProvider = Provider.family<ServiceRequest?, String>((
  ref,
  id,
) {
  for (final r in ref.watch(serviceRequestsProvider)) {
    if (r.id == id) return r;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Reminders & activity
// ---------------------------------------------------------------------------

final remindersProvider = Provider<List<Reminder>>((ref) => MockData.reminders);

final activityProvider = Provider<List<ActivityItem>>((ref) {
  final txs = ref.watch(transactionsProvider);
  final requests = ref.watch(serviceRequestsProvider);
  final items = [
    ...txs.map(ActivityItem.fromTransaction),
    ...requests.map(ActivityItem.fromRequest),
  ]..sort((a, b) => b.date.compareTo(a.date));
  return items;
});

final paymentMethodsProvider = Provider<List<PaymentMethod>>(
  (ref) => CatalogRepository.paymentMethods,
);

final plansProvider = Provider.family<List<UtilityPlan>, UtilityType>(
  (ref, type) => CatalogRepository.plansFor(type),
);
