import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/real_gui_chaptered_continuation_probe.dart';

void main() {
  HttpOverrides.global = null;

  test(
    'real GUI chaptered continuation probe validates continuity and chapter length through controller path',
    () async {
      final report = await runRealGuiChapteredContinuationProbe();
      if (!ValueReaders.boolValue(report['ok'])) {
        final laneId = ValueReaders.stringValue(report['lane_id']);
        final runId = ValueReaders.stringValue(report['run_id']);
        fail(
          'GUI chaptered continuation probe failed. artifacts/high_fidelity_viewmodel_validation/$runId/$laneId/lane_report.json',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 25)),
    skip: !_realProbeEnabled(),
  );
}

bool _realProbeEnabled() {
  final raw = Platform.environment['NOVEL_AGENT_ENABLE_REAL_PROBES'] ?? '';
  final normalized = raw.trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
