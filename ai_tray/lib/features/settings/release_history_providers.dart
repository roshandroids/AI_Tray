import 'package:ai_tray/features/settings/data/release_history_asset_loader.dart';
import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Live package metadata baked into the binary (pubspec version / build).
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Generated release notes asset (`assets/release_history.json`).
final releaseHistoryProvider = FutureProvider<ReleaseHistory>((ref) {
  return const ReleaseHistoryAssetLoader().load();
});
