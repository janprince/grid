import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid/app/app.dart';
import 'package:grid/core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderScope> _app({required Map<String, Object> prefs}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(sharedPrefs)],
    child: const GridApp(),
  );
}

void main() {
  testWidgets('first launch shows onboarding after splash', (tester) async {
    await tester.pumpWidget(await _app(prefs: {}));
    // Splash shows the brand, then routes onward.
    expect(find.text('GRID'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pay utilities with ease'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('returning logged-out user lands on login', (tester) async {
    await tester.pumpWidget(await _app(prefs: {'onboarding_done': true}));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Welcome to GRID'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('logged-in user lands on the dashboard with mock data', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _app(
        prefs: {
          'onboarding_done': true,
          'logged_in': true,
          'user_name': 'Kwame Mensah',
          'user_phone': '+233551234567',
        },
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Greeting + selected home + quick actions.
    expect(find.text('Kwame'), findsOneWidget);
    expect(find.text('My Home'), findsWidgets);
    expect(find.text('Buy ECG'), findsOneWidget);
    expect(find.text('Book Service'), findsOneWidget);

    // Reminders render further down the scroll view.
    await tester.scrollUntilVisible(
      find.text('DStv expires tomorrow'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upcoming reminders'), findsOneWidget);
    expect(find.text('DStv expires tomorrow'), findsOneWidget);
  });

  testWidgets('ECG purchase golden path completes with a receipt', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _app(
        prefs: {
          'onboarding_done': true,
          'logged_in': true,
          'user_name': 'Kwame Mensah',
          'user_phone': '+233551234567',
        },
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Dashboard quick action → account step with saved meters.
    await tester.ensureVisible(find.text('Buy ECG'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Buy ECG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('My Home Meter'), findsOneWidget);

    await tester.tap(find.text('My Home Meter'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));

    // Amount step — pick a quick amount.
    expect(find.text('How much?'), findsOneWidget);
    await tester.tap(find.text('GH₵ 100'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));

    // Method step — MTN MoMo preselected as default.
    expect(find.text('Pay with'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));

    // Review step — explicit confirmation.
    expect(find.text('Review your payment'), findsOneWidget);
    await tester.tap(find.textContaining('Confirm & pay'));
    await tester.pump(const Duration(milliseconds: 200));

    // Processing → success receipt with token.
    expect(find.textContaining('Processing'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('YOUR POWER TOKEN'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('bottom navigation reaches all five tabs', (tester) async {
    await tester.pumpWidget(
      await _app(
        prefs: {
          'onboarding_done': true,
          'logged_in': true,
          'user_name': 'Kwame Mensah',
          'user_phone': '+233551234567',
        },
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Pay'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Pay bills'), findsOneWidget);

    await tester.tap(find.text('Services'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Home services'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Payments'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Manage homes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Log out'), findsOneWidget);
  });
}
