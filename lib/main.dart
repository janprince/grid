import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/data/api/api_config.dart';
import 'core/data/api/session_store.dart';
import 'core/data/app_prefs.dart';
import 'core/data/asset_catalog.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AssetCatalog.load();
  final prefs = await SharedPreferences.getInstance();

  // Read the stored session before the first frame so the router knows
  // whether to open on sign-in or home.
  final sessions = SessionStore();
  if (ApiConfig.useApi) {
    if (AppPrefs(prefs).onboardingDone) {
      await sessions.load();
    } else {
      // iOS keeps keychain items across reinstalls; a fresh install starts signed out.
      await sessions.clear();
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        sessionStoreProvider.overrideWithValue(sessions),
      ],
      child: const GridApp(),
    ),
  );
}
