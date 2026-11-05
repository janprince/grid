import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid/app/app.dart';
import 'package:grid/core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderScope> _app({required Map<String, Object> prefs}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
      // The widget tests run on the bundled mock data, never the network.
      apiEnabledProvider.overrideWithValue(false),
    ],
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
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('phone sign-up walks through OTP and profile setup', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(prefs: {'onboarding_done': true}));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Phone is the only way in.
    expect(find.text('Email'), findsNothing);
    await tester.enterText(find.byType(TextFormField), '0551234567');
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    expect(find.textContaining('Test code: 123456'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    // A new person names themselves; last name and email are optional.
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name (optional)'), findsOneWidget);
    await tester.tap(find.text('ENTER GRID'));
    await tester.pump();
    expect(find.text('Your first name is required'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Akosua',
    );
    await tester.tap(find.text('ENTER GRID'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Akosua'), findsWidgets);
    expect(find.text('My Home'), findsWidgets);
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

    // Greeting + selected home + pay shortcuts. The greeting and the name
    // are one line on the forest ground, and the hero's own call to action
    // ("Top up power") is distinct from the "Buy ECG" shortcut below it.
    expect(find.textContaining('Kwame'), findsWidgets);
    expect(find.text('My Home'), findsWidgets);
    expect(find.text('TOP UP POWER'), findsOneWidget);
    expect(find.text('Buy ECG'), findsOneWidget);
    expect(find.text('Book a service'), findsOneWidget);

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
    // Continue checks the meter with the biller before moving on.
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));

    // Amount step — the biller's name for the meter, then a quick amount.
    expect(find.text('How much?'), findsOneWidget);
    expect(find.text('GRID Demo Customer'), findsOneWidget);
    await tester.tap(find.text('GH₵ 100'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 400));

    // Review step — paying from the signed-in MoMo number.
    expect(find.text('Review your payment'), findsOneWidget);
    expect(find.textContaining('MTN Mobile Money'), findsOneWidget);
    await tester.tap(find.textContaining('CONFIRM & PAY'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Sending the payment request'), findsOneWidget);

    // The prompt is out; the order settles while the screen waits.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Approve on your phone'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
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
    expect(find.text('What can we take off your hands?'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Payments'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('My homes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Log out'), findsOneWidget);
  });
}
