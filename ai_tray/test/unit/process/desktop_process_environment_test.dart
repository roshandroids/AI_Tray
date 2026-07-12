import 'dart:io';

import 'package:ai_tray/features/providers/data/process/desktop_process_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveExecutable returns absolute path for known binaries', () {
    final claude = File('/opt/homebrew/bin/claude');
    if (!claude.existsSync()) {
      return; // Skip on machines without Homebrew Claude.
    }
    final resolved = DesktopProcessEnvironment.resolveExecutable('claude');
    expect(resolved, '/opt/homebrew/bin/claude');
  });

  test('enriched PATH includes Homebrew entries', () {
    final path = DesktopProcessEnvironment.enriched()['PATH'] ?? '';
    expect(path.contains('/opt/homebrew/bin'), isTrue);
  });
}
