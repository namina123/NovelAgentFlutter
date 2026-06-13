import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'long_task_stability_mock_regression_suite_support.dart';

Future<void> main() async {
  final report = await runLongTaskStabilityMockRegressionSuite();
  final summary = ValueReaders.mapValue(report['summary']);
  final scenarios = ValueReaders.mapList(report['scenarios']);

  stdout.writeln('=== LTSR-20 Mainline Mock Regression Suite ===');
  stdout.writeln('workspace: ${ValueReaders.stringValue(report['workspace_root'])}');
  stdout.writeln(
    'report_json: ${ValueReaders.stringValue(report['report_json_path'])}',
  );
  stdout.writeln(
    'report_markdown: ${ValueReaders.stringValue(report['report_markdown_path'])}',
  );
  stdout.writeln(
    'passed: ${ValueReaders.intValue(summary['passed_scenarios'])}/${ValueReaders.intValue(summary['total_scenarios'])}',
  );
  for (final rawScenario in scenarios) {
    final scenario = ValueReaders.mapValue(rawScenario);
    final prefix = ValueReaders.boolValue(scenario['ok']) ? '[PASS]' : '[FAIL]';
    stdout.writeln(
      '$prefix ${ValueReaders.stringValue(scenario['id'])} => ${ValueReaders.stringValue(scenario['observed_category'])}',
    );
  }

  if (!ValueReaders.boolValue(summary['all_required_coverage_passed'])) {
    exitCode = 1;
  }
}
