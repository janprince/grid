import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid/app/app.dart';
import 'package:grid/core/data/app_prefs.dart';
import 'package:grid/core/models/models.dart';
import 'package:grid/core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

Future<ProviderScope> _app({
  required Map<String, Object> prefs,
  FakeBillPaymentsApi? bills,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final homes = FakeHomeStore();
  return ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
      // The widget tests run on in-memory fakes, never the network.
      authApiProvider.overrideWithValue(FakeAuthApi(AppPrefs(sharedPrefs))),
      propertiesApiProvider.overrideWithValue(homes),
      utilityAccountsApiProvider.overrideWithValue(
        FakeUtilityAccountsApi(homes),
      ),
      billPaymentsApiProvider.overrideWithValue(bills ?? FakeBillPaymentsApi()),
      servicesApiProvider.overrideWithValue(FakeServicesApi()),
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
    expect(find.text('Continue'), findsOneWidget);
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
    await tester.tap(find.text('Continue'));
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
    await tester.tap(find.text('Enter GRID'));
    await tester.pump();
    expect(find.text('Your first name is required'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Akosua',
    );
    await tester.tap(find.text('Enter GRID'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Akosua'), findsWidgets);
    expect(find.text('My Home'), findsWidgets);
  });

  testWidgets('logged-in user lands on the dashboard', (tester) async {
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
    expect(find.text('Top up power'), findsOneWidget);
    expect(find.text('Buy ECG'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Book a service'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Book a service'), findsOneWidget);
  });

  testWidgets('ECG purchase golden path completes with a receipt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    // Dashboard quick action → the meter question, with saved meters below.
    await tester.ensureVisible(find.text('Buy ECG'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Buy ECG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Buy ECG power'), findsOneWidget);
    expect(find.text('My Home Meter'), findsOneWidget);

    // A saved meter is checked with the biller straight away.
    await tester.tap(find.text('My Home Meter'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));

    // Amount step — who is being paid sits above the button.
    expect(find.text('How much?'), findsOneWidget);
    expect(find.text('Test Customer'), findsOneWidget);
    await tester.tap(find.text('GH₵ 100'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    // The confirm sheet — paying from the signed-in MoMo number.
    expect(find.text('Confirm payment'), findsOneWidget);
    expect(find.textContaining('MTN Mobile Money'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    await tester.tap(find.text('Pay GH₵ 100.00'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Sending the payment request'), findsOneWidget);

    // The prompt is out; the order settles while the screen waits.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Approve on your phone'), findsOneWidget);
    expect(find.text('Need help?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('airtime starts with the network, then the number', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(find.text('What are you paying for?'), findsOneWidget);
    await tester.ensureVisible(find.text('Airtime'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Airtime'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Select the recipient\'s network'), findsOneWidget);
    await tester.tap(find.text('MTN'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Recipient\'s MTN number'), findsOneWidget);
    expect(find.text('Choose from contacts'), findsOneWidget);
    await tester.tap(find.text('Use my number'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('How much airtime?'), findsOneWidget);
    expect(find.text('My number'), findsOneWidget);
  });

  testWidgets('opening Activity shows an order that settled in the meantime', (
    tester,
  ) async {
    final bills = FakeBillPaymentsApi();
    await tester.pumpWidget(
      await _app(
        prefs: {
          'onboarding_done': true,
          'logged_in': true,
          'user_name': 'Kwame Mensah',
          'user_phone': '+233551234567',
        },
        bills: bills,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // The list already loaded, empty, before this order finished.
    bills.addFromServer(
      BillOrder(
        id: 'o1',
        reference: 'GRID-TEST',
        productCode: 'EcgPrepaid',
        accountNumber: 'P20314039',
        customerName: 'Paid Meter Owner',
        principal: 1,
        fee: 0,
        total: 1,
        status: BillOrderStatus.completed,
        createdAt: DateTime.now(),
        channel: 'mtn-gh',
      ),
    );

    await tester.tap(find.text('Activity'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Paid Meter Owner'), findsOneWidget);
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
    expect(find.text('Cleaning & laundry'), findsOneWidget);
    for (final service in fakeCatalogue.services) {
      await tester.scrollUntilVisible(
        find.text(service.name),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(service.name), findsOneWidget);
    }

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

  testWidgets('a service page builds a booking and the flow starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    await tester.tap(find.text('Services'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Home cleaning'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Sizes of one job are alternatives; a countable item adds up.
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('2 bedrooms'),
      200,
      scrollable: page,
    );
    await tester.tap(find.text('2 bedrooms'));
    await tester.pump();
    expect(find.text('GH₵ 250.00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add'), 200, scrollable: page);
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.tap(find.byTooltip('One more seat'));
    await tester.pump();
    expect(find.text('GH₵ 370.00'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Where is the job?'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
  });
}
