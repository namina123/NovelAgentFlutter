import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/hfvv_wave2_viewmodel_runner.dart';

const String _envRunId = String.fromEnvironment('HFVV_WAVE2_RUN_ID');
const String _envLaneCsv = String.fromEnvironment('HFVV_WAVE2_LANES');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'HFVV-06 Wave 2 real runner emits four lane reports',
    () async {
      final config = HfvvWave2RunConfig(
        runId: _resolvedRunId(),
        enabledLaneIds: _resolvedLaneCsv().trim().isEmpty
            ? const <String>{}
            : _resolvedLaneCsv()
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet(),
      );
      final expectedLaneCount = resolveHfvvWave2LaneIds(
        enabledLaneIds: config.enabledLaneIds,
      ).length;
      final summary = await runHfvvWave2(
        requireRealProbeOptIn: false,
        config: config,
      );
      final lanes = ValueReaders.objectList(summary['lanes']);
      expect(lanes, hasLength(expectedLaneCount));
      debugPrint(const JsonEncoder.withIndent('  ').convert(summary));
    },
    timeout: const Timeout(Duration(hours: 6)),
  );
}

String _defaultRunIdForTest() => '2026-06-10T01-35-42';

String _resolvedRunId() {
  if (_envRunId.trim().isNotEmpty) {
    return _envRunId.trim();
  }
  final environmentRunId =
      (Platform.environment['HFVV_WAVE2_RUN_ID'] ?? '').trim();
  return environmentRunId.isEmpty ? _defaultRunIdForTest() : environmentRunId;
}

String _resolvedLaneCsv() {
  if (_envLaneCsv.trim().isNotEmpty) {
    return _envLaneCsv.trim();
  }
  return (Platform.environment['HFVV_WAVE2_LANES'] ?? '').trim();
}
