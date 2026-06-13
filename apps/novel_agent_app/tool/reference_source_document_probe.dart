import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main() async {
  final repoRoot = resolveLocalProbeRepoRoot();
  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'reference_source_document_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);
  final substrateRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}substrate',
  )..createSync(recursive: true);
  final bundleRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}bundle',
  );
  final sourceFile = File(
    '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files${Platform.pathSeparator}Harry Potter.txt',
  );
  final report = <String, Object?>{
    'probe_name': 'reference_source_document_probe',
    'run_id': runId,
    'workspace_root': workspaceRoot.path,
    'source_file': sourceFile.path,
    'started_at': DateTime.now().toIso8601String(),
  };
  try {
    if (!sourceFile.existsSync()) {
      throw StateError('Source file missing: ${sourceFile.path}');
    }
    final substrate = SqliteReferenceEvidenceSubstrate(
      substrateRootPath: substrateRoot.path,
    );
    final ingestionService = ReferenceSourceDocumentFileIngestionService(
      substrate: substrate,
    );
    final result = await ingestionService.ingestFile(
      sourceFilePath: sourceFile.path,
      packageId: 'harry_potter_full_text',
      packageKind: ReferencePackageKinds.referenceWorkPackage,
      displayName: '哈利波特原始书稿参考包',
      packageVersionId: 'v1',
      versionLabel: 'full-text-probe',
      createdAt: DateTime.now().toIso8601String(),
      createdBy: 'reference_source_document_probe',
      targetLanguage: 'zh-CN',
      bundleOutputDirectory: bundleRoot.path,
      maxChapterEntries: 8,
      maxEntityEntries: 8,
    );
    final entryKindCounts = <String, int>{};
    for (final entry in result.snapshot.entries) {
      entryKindCounts[entry.entryKind] =
          (entryKindCounts[entry.entryKind] ?? 0) + 1;
    }
    report['ok'] = true;
    report['package_id'] = result.packageId;
    report['package_version_id'] = result.packageVersionId;
    report['source_language'] = result.sourceLanguage;
    report['target_language'] = result.targetLanguage;
    report['generated_entry_count'] = result.generatedEntryCount;
    report['entry_kind_counts'] = entryKindCounts;
    report['bundle_output_directory'] = result.bundleOutputDirectory;
    report['summary_projection_path'] =
        '${bundleRoot.path}${Platform.pathSeparator}projections${Platform.pathSeparator}summary.md';
    report['entry_titles'] = result.snapshot.entries
        .take(10)
        .map((entry) => entry.title)
        .toList(growable: false);
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_source_document_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final markdownFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_source_document_probe_report.md',
    );
    await markdownFile.writeAsString(_reportMarkdown(report));
    stdout.writeln('report: ${reportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

String _reportMarkdown(Map<String, Object?> report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final lines = <String>[
    '# 原始书稿参考包探针报告',
    '',
    '- 结果：${ok ? 'PASS' : 'FAIL'}',
    '- 源文件：${ValueReaders.stringValue(report['source_file'])}',
    '- 工作区：${ValueReaders.stringValue(report['workspace_root'])}',
  ];
  if (ok) {
    lines.addAll(<String>[
      '- 资料包 ID：${ValueReaders.stringValue(report['package_id'])}',
      '- 版本 ID：${ValueReaders.stringValue(report['package_version_id'])}',
      '- 源语言：${ValueReaders.stringValue(report['source_language'])}',
      '- 目标语言：${ValueReaders.stringValue(report['target_language'])}',
      '- 生成条目数：${ValueReaders.intValue(report['generated_entry_count'])}',
      '- Bundle 输出：${ValueReaders.stringValue(report['bundle_output_directory'])}',
      '- 摘要投影：${ValueReaders.stringValue(report['summary_projection_path'])}',
    ]);
  } else {
    lines.add('- 错误：${ValueReaders.stringValue(report['error'])}');
  }
  lines.add('');
  return '${lines.join('\n')}\n';
}
