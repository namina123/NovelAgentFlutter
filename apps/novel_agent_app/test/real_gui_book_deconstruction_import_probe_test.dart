import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/real_gui_book_deconstruction_import_probe.dart';

void main() {
  HttpOverrides.global = null;

  test(
    'real GUI book deconstruction import probe validates source retention, discovery, continuation split and smart analysis visibility',
    () async {
      final report = await runRealGuiBookDeconstructionImportProbe();
      if (!ValueReaders.boolValue(report['ok'])) {
        final runId = ValueReaders.stringValue(report['run_id']);
        fail(
          'GUI book deconstruction import probe failed. artifacts/real_gui_book_deconstruction_import_probe_report.json (run_id=$runId)',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 25)),
    skip: !_realProbeEnabled(),
  );
}

bool _realProbeEnabled() {
  // 中文注释: 真实探针默认关闭，只有显式开闸时才允许跑，避免误耗本地或远端额度。
  final raw = Platform.environment['NOVEL_AGENT_ENABLE_REAL_PROBES'] ?? '';
  final normalized = raw.trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
