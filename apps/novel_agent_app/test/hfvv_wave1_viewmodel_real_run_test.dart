import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/hfvv_wave1_viewmodel_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'HFVV-04 Wave 1 real runner emits five lane reports',
    () async {
      final summary = await runHfvvWave1(requireRealProbeOptIn: false);
      final lanes = ValueReaders.objectList(summary['lanes']);
      expect(lanes, hasLength(5));
      debugPrint(const JsonEncoder.withIndent('  ').convert(summary));
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
