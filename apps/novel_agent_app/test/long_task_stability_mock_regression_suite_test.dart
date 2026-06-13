import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/long_task_stability_mock_regression_suite_support.dart';

void main() {
  group('long task stability mock regression suite', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_ltsr20_mock_suite_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('covers all LTSR-20 required scenarios with production-backed report', () async {
      final report = await runLongTaskStabilityMockRegressionSuite(
        repoRootOverride: tempDirectory.path,
        runIdOverride: '2026-06-07T12:00:00.000Z',
      );
      final summary = ValueReaders.mapValue(report['summary']);
      final scenarios = ValueReaders.mapList(report['scenarios'])
          .map(ValueReaders.mapValue)
          .toList(growable: false);
      final requiredCoverage = ValueReaders.mapList(summary['required_coverage'])
          .map(ValueReaders.mapValue)
          .toList(growable: false);

      expect(ValueReaders.intValue(summary['total_scenarios']), 8);
      expect(ValueReaders.intValue(summary['passed_scenarios']), 8);
      expect(
        ValueReaders.boolValue(summary['all_required_coverage_passed']),
        isTrue,
      );
      expect(
        requiredCoverage.map((item) => ValueReaders.stringValue(item['requirement'])),
        containsAll(const <String>[
          'ordinary_project_self_review',
          'long_task_proactive_review',
          'reviewer_dispatch',
          'delivery_failure',
          'repair_required',
          'waiting_user',
          'manual_attention',
          'natural_completion',
        ]),
      );
      expect(
        scenarios.map((scenario) => ValueReaders.stringValue(scenario['id'])),
        containsAll(const <String>[
          'ordinary_project_self_review',
          'reviewer_dispatch',
          'long_task_proactive_review',
          'delivery_failure',
          'repair_required',
          'waiting_user',
          'manual_attention',
          'natural_completion',
        ]),
      );
      final stopScenarios = scenarios
          .where(
            (scenario) => const <String>{
              'delivery_failure',
              'repair_required',
              'waiting_user',
              'manual_attention',
              'natural_completion',
            }.contains(ValueReaders.stringValue(scenario['id'])),
          )
          .toList(growable: false);
      for (final scenario in stopScenarios) {
        final runCenterContract = ValueReaders.mapValue(
          scenario['run_center_contract'],
        );
        final stopDiagnosis = ValueReaders.mapValue(
          runCenterContract['stop_diagnosis'],
        );
        expect(runCenterContract, isNotEmpty);
        expect(ValueReaders.boolValue(stopDiagnosis['present']), isTrue);
        expect(
          ValueReaders.stringValue(stopDiagnosis['category']),
          ValueReaders.stringValue(scenario['observed_category']),
        );
      }

      final reportJson = File(ValueReaders.stringValue(report['report_json_path']));
      final reportMarkdown = File(
        ValueReaders.stringValue(report['report_markdown_path']),
      );
      expect(await reportJson.exists(), isTrue);
      expect(await reportMarkdown.exists(), isTrue);
    });
  });
}
