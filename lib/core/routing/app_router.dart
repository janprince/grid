import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/activity_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/home/dashboard_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/payments/payment_flow_screen.dart';
import '../../features/payments/pay_hub_screen.dart';
import '../../features/payments/saved_accounts_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screens.dart';
import '../../features/properties/add_edit_property_screen.dart';
import '../../features/properties/property_details_screen.dart';
import '../../features/properties/properties_screen.dart';
import '../../features/services/booking_flow_screen.dart';
import '../../features/services/request_details_screen.dart';
import '../../features/services/services_hub_screen.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import 'main_shell.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _authRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.login,
  Routes.otp,
  Routes.profileSetup,
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(sessionProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;
      if (path == Routes.splash) return null;

      switch (session.status) {
        case AuthStatus.needsOnboarding:
          return path == Routes.onboarding ? null : Routes.onboarding;
        case AuthStatus.loggedOut:
          return _authRoutes.contains(path) && path != Routes.onboarding
              ? null
              : Routes.login;
        case AuthStatus.loggedIn:
          return _authRoutes.contains(path) ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (context, state) => OtpScreen(args: state.extra as OtpArgs),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (context, state) =>
            ProfileSetupScreen(args: state.extra as ProfileSetupArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.pay,
                builder: (context, state) => const PayHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.services,
                builder: (context, state) => const ServicesHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen flows presented over the shell (no bottom nav).
      GoRoute(
        path: '/pay/flow/:type',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type =
              UtilityType.values.asNameMap()[state.pathParameters['type']] ??
              UtilityType.ecg;
          return PaymentFlowScreen(
            type: type,
            initialAccountId: state.uri.queryParameters['account'],
          );
        },
      ),
      GoRoute(
        path: Routes.savedAccounts,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavedAccountsScreen(),
      ),
      GoRoute(
        path: Routes.bookService,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            BookingFlowScreen(args: state.extra as BookingArgs?),
      ),
      GoRoute(
        path: '/services/request/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RequestDetailsScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.properties,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: Routes.addProperty,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditPropertyScreen(),
      ),
      GoRoute(
        path: '/properties/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            PropertyDetailsScreen(propertyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/properties/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AddEditPropertyScreen(propertyId: state.pathParameters['id']),
      ),
      GoRoute(
        path: Routes.paymentMethods,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationPrefsScreen(),
      ),
      GoRoute(
        path: Routes.help,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpCentreScreen(),
      ),
      GoRoute(
        path: Routes.privacy,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
    ],
  );
});
