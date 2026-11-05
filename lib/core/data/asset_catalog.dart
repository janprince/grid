import 'package:flutter/services.dart';

/// Which optional artwork actually shipped in this build.
///
/// Biller logos and service photography are both add-as-you-get-them: the
/// app must look finished whether or not a given file exists. Relying on
/// `Image.asset`'s `errorBuilder` to notice a missing file is not dependable
/// — on web a missing asset can resolve to a 200 response the decoder simply
/// fails on, and the widget renders nothing at all rather than falling back.
///
/// So the manifest is read once at startup and consulted synchronously.
/// Adding `ecg.webp` to `assets/images/billers/` is then the only step needed
/// to light that mark up; nothing else has to change.
abstract final class AssetCatalog {
  static Set<String> _available = const {};

  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _available = manifest.listAssets().toSet();
    } on Exception {
      // A build with no manifest simply has no optional artwork.
      _available = const {};
    }
  }

  static bool has(String? path) => path != null && _available.contains(path);
}
