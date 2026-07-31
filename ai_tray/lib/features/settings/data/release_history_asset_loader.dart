import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:flutter/services.dart';

/// Loads generated release history from the Flutter asset bundle.
final class ReleaseHistoryAssetLoader {
  const ReleaseHistoryAssetLoader({
    this.assetBundle,
    this.assetPath = ReleaseHistory.assetPath,
  });

  final AssetBundle? assetBundle;
  final String assetPath;

  Future<ReleaseHistory> load() async {
    final bundle = assetBundle ?? rootBundle;
    final raw = await bundle.loadString(assetPath);
    return ReleaseHistory.parse(raw);
  }
}
