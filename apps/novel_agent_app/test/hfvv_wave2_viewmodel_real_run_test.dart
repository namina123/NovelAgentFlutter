import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/hfvv_wave2_viewmodel_runner.dart';

const String _envRunId = String.fromEnvironment('HFVV_WAVE2_RUN_ID');
const String _envLaneCsv = String.fromEnvironment('HFVV_WAVE2_LANES');
const String _envChapterCount = String.fromEnvironment(
  'HFVV_WAVE2_CHAPTER_COUNT',
);
const String _envCheckpointInterval = String.fromEnvironment(
  'HFVV_WAVE2_CHECKPOINT_INTERVAL',
);
const String _envTargetEffectiveChapters = String.fromEnvironment(
  'HFVV_WAVE2_TARGET_EFFECTIVE_CHAPTERS',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'HFVV-06 Wave 2 smoke runner emits a lane report',
    () async {
      final config = HfvvWave2RunConfig(
        runId: _resolvedRunId(),
        enabledLaneIds: _resolvedLaneCsv().trim().isEmpty
            ? <String>{'lane_g_general_long_task_stability'}
            : _resolvedLaneCsv()
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet(),
        chapterCountOverride: _resolvedInt(
          _envChapterCount,
          const String.fromEnvironment('HFVV_WAVE2_CHAPTER_COUNT'),
          fallback: 1,
        ),
        checkpointIntervalOverride: _resolvedInt(
          _envCheckpointInterval,
          const String.fromEnvironment('HFVV_WAVE2_CHECKPOINT_INTERVAL'),
          fallback: 1,
        ),
        targetEffectiveChapterCountOverride: _resolvedInt(
          _envTargetEffectiveChapters,
          const String.fromEnvironment('HFVV_WAVE2_TARGET_EFFECTIVE_CHAPTERS'),
          fallback: 1,
        ),
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

String _defaultRunIdForTest() =>
    'hfvv_wave2_${DateTime.now().microsecondsSinceEpoch}';

String _resolvedRunId() {
  if (_envRunId.trim().isNotEmpty) {
    return _envRunId.trim();
  }
  final environmentRunId = (Platform.environment['HFVV_WAVE2_RUN_ID'] ?? '')
      .trim();
  return environmentRunId.isEmpty ? _defaultRunIdForTest() : environmentRunId;
}

String _resolvedLaneCsv() {
  if (_envLaneCsv.trim().isNotEmpty) {
    return _envLaneCsv.trim();
  }
  return (Platform.environment['HFVV_WAVE2_LANES'] ?? '').trim();
}

int _resolvedInt(
  String compileTimeValue,
  String envValue, {
  required int fallback,
}) {
  final raw = compileTimeValue.trim().isNotEmpty
      ? compileTimeValue.trim()
      : envValue.trim().isNotEmpty
      ? envValue.trim()
      : '';
  final parsed = int.tryParse(raw);
  return parsed == null || parsed <= 0 ? fallback : parsed;
}
