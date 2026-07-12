import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('InMemoryUsageCache write/read/clear', () async {
    final cache = InMemoryUsageCache();
    expect((await cache.read()).valueOrNull, isNull);

    final usage = UsageInfo(
      sessionUsedPercent: 9,
      fetchedAt: DateTime.utc(2026, 7, 12),
      source: UsageSource.cli,
      isFromCache: false,
      providerId: ProviderId.claude,
    );
    await cache.write(usage);
    final read = await cache.read();
    expect(read.valueOrNull?.sessionUsedPercent, 9);
    expect(read.valueOrNull?.isFromCache, isTrue);

    await cache.clear();
    expect((await cache.read()).valueOrNull, isNull);
  });

  test('SharedPreferencesUsageCache round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesUsageCache(prefs);

    final usage = UsageInfo(
      sessionUsedPercent: 22,
      sessionResetsAtRaw: 'later',
      fetchedAt: DateTime.utc(2026, 7, 12, 15),
      source: UsageSource.cli,
      isFromCache: false,
      providerId: ProviderId.claude,
    );

    final written = await cache.write(usage);
    expect(written.isSuccess, isTrue);

    final read = await cache.read();
    expect(read.valueOrNull?.sessionUsedPercent, 22);
    expect(read.valueOrNull?.sessionResetsAtRaw, 'later');
    expect(read.valueOrNull?.isFromCache, isTrue);

    await cache.clear();
    expect((await cache.read()).valueOrNull, isNull);
  });

  test('SharedPreferencesUsageCache rejects corrupt JSON', () async {
    SharedPreferences.setMockInitialValues({'usage_lkg_v1': '{not-json'});
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesUsageCache(prefs);
    final read = await cache.read();
    expect(read.isFailure, isTrue);
  });
}
