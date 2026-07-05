import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final authApiProvider = Provider<AuthApi>((ref) => MockAuthApi());
final paymentsApiProvider = Provider<PaymentsApi>((ref) => MockPaymentsApi());
final servicesApiProvider = Provider<ServicesApi>((ref) => MockServicesApi());

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

enum AuthStatus { needsOnboarding, loggedOut, loggedIn }

class SessionState {
  const SessionState({required this.status, this.user});

  final AuthStatus status;
  final AppUser? user;
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    final prefs = ref.watch(appPrefsProvider);
    if (!prefs.onboardingDone) {
      return const SessionState(status: AuthStatus.needsOnboarding);
    }
    if (prefs.loggedIn) {
      return SessionState(
        status: AuthStatus.loggedIn,
        user: AppUser(
          id: 'u1',
          name: prefs.userName ?? MockData.user.name,
          phone: prefs.userPhone ?? MockData.user.phone,
          email: prefs.userEmail,
        ),
      );
    }
    return const SessionState(status: AuthStatus.loggedOut);
  }

  Future<void> completeOnboarding() async {
    await ref.read(appPrefsProvider).setOnboardingDone();
    state = const SessionState(status: AuthStatus.loggedOut);
  }

  Future<void> signIn({
    required String name,
    required String phone,
    String? email,
  }) async {
    await ref
        .read(appPrefsProvider)
        .saveSession(name: name, phone: phone, email: email);
    state = SessionState(
      status: AuthStatus.loggedIn,
      user: AppUser(id: 'u1', name: name, phone: phone, email: email),
    );
  }

  Future<void> signOut() async {
    await ref.read(appPrefsProvider).clearSession();
    state = const SessionState(status: AuthStatus.loggedOut);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

class PropertiesNotifier extends Notifier<List<Property>> {
  @override
  List<Property> build() => List.of(MockData.properties);

  void add(Property property) {
    var next = [...state, property];
    if (property.isPrimary) next = _withSinglePrimary(next, property.id);
    state = next;
  }

  void update(Property property) {
    var next = [for (final p in state) p.id == property.id ? property : p];
    if (property.isPrimary) next = _withSinglePrimary(next, property.id);
    state = next;
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
    if (ref.read(selectedPropertyIdProvider) == id) {
      ref
          .read(selectedPropertyIdProvider.notifier)
          .select(state.isEmpty ? null : state.first.id);
    }
  }

  void setPrimary(String id) => state = _withSinglePrimary(state, id);

  static List<Property> _withSinglePrimary(
    List<Property> list,
    String primaryId,
  ) => [for (final p in list) p.copyWith(isPrimary: p.id == primaryId)];
}

final propertiesProvider = NotifierProvider<PropertiesNotifier, List<Property>>(
  PropertiesNotifier.new,
);

class SelectedPropertyIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final properties = MockData.properties;
    return properties
        .firstWhere((p) => p.isPrimary, orElse: () => properties.first)
        .id;
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
  return properties.firstWhere(
    (p) => p.id == id,
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

class AccountsNotifier extends Notifier<List<UtilityAccount>> {
  @override
  List<UtilityAccount> build() => List.of(MockData.accounts);

  void add(UtilityAccount account) {
    var next = [...state, account];
    if (account.isDefault) next = _withSingleDefault(next, account);
    state = next;
  }

  void update(UtilityAccount account) {
    var next = [for (final a in state) a.id == account.id ? account : a];
    if (account.isDefault) next = _withSingleDefault(next, account);
    state = next;
  }

  void remove(String id) => state = state.where((a) => a.id != id).toList();

  void markPaid(String id, double amount) {
    state = [
      for (final a in state)
        a.id == id
            ? a.copyWith(lastPaidAt: DateTime.now(), lastAmount: amount)
            : a,
    ];
  }

  static List<UtilityAccount> _withSingleDefault(
    List<UtilityAccount> list,
    UtilityAccount account,
  ) => [
    for (final a in list)
      a.type == account.type ? a.copyWith(isDefault: a.id == account.id) : a,
  ];
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

class TransactionsNotifier extends Notifier<List<PaymentTransaction>> {
  @override
  List<PaymentTransaction> build() => List.of(MockData.transactions);

  void insert(PaymentTransaction tx) => state = [tx, ...state];
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
