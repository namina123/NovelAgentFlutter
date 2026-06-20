import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_information_scan_runtime.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkspaceInformationScanRuntime', () {
    test(
      'scan collects hidden support entries and skips reference extraction bundle subtree',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workspace_information_scan_runtime_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        await _writeProjectFile(
          tempDirectory.path,
          'knowledge/项目知识摘要.md',
          _projectionMarkdown(
            title: '知识摘要',
            sourceOfTruthPath: 'project-information://knowledge_cards',
            sourceIdentity:
                '来源-source-1 / `imports/reference/source-1.txt` / kind:`user`',
          ),
        );
        await _writeProjectFile(
          tempDirectory.path,
          '.novel_agent/information/knowledge_cards/knowledge_1.json',
          jsonEncode(<String, Object?>{
            'card_id': 'knowledge_1',
            'title': '王朝年号',
            'summary': '需要确认帝国年号是否已经固定。',
            'lifecycle_status': InformationLifecycleStatuses.proposed,
          }),
        );
        await _writeProjectFile(
          tempDirectory.path,
          '.novel_agent/reference_extraction/bundles/bundle_1/activation_report.json',
          '{invalid-json',
        );

        final runtime = WorkspaceInformationScanRuntime();
        final result = await runtime.scan(
          projectRootPath: tempDirectory.path,
          workspaceEntries: const <JsonMap>[
            <String, Object?>{
              'relative_path': 'knowledge/项目知识摘要.md',
              'is_dir': false,
            },
          ],
        );

        final paths = result.workspaceEntries
            .map((entry) => ValueReaders.stringValue(entry['relative_path']))
            .toList(growable: false);
        expect(paths, contains('knowledge/项目知识摘要.md'));
        expect(
          paths,
          contains('.novel_agent/information/knowledge_cards/knowledge_1.json'),
        );
        expect(
          paths,
          isNot(
            contains(
              '.novel_agent/reference_extraction/bundles/bundle_1/activation_report.json',
            ),
          ),
        );
        expect(
          result.fileContents.keys,
          contains('knowledge/项目知识摘要.md'),
        );
        expect(
          result.sourcePaths,
          contains('knowledge/项目知识摘要.md'),
        );
      },
    );

    test(
      'scan reads sqlite-first structured information records without requiring projection markdown',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workspace_information_scan_runtime_sqlite_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        await _writeProjectFile(
          tempDirectory.path,
          '.novel_agent/information/knowledge_cards/knowledge_1.json',
          jsonEncode(<String, Object?>{
            'card_id': 'knowledge_1',
            'title': '王朝年号',
          }),
        );

        final runtime = WorkspaceInformationScanRuntime();
        final result = await runtime.scan(
          projectRootPath: tempDirectory.path,
          workspaceEntries: const <JsonMap>[],
        );

        expect(
          result.fileContents.keys,
          contains('.novel_agent/information/knowledge_cards/knowledge_1.json'),
        );
        expect(
          result.sourcePaths,
          contains('.novel_agent/information/knowledge_cards/knowledge_1.json'),
        );
      },
    );
  });
}

Future<void> _writeProjectFile(
  String rootPath,
  String relativePath,
  String content,
) async {
  final normalizedRelative = relativePath.replaceAll(
    '/',
    Platform.pathSeparator,
  );
  final file = File('$rootPath${Platform.pathSeparator}$normalizedRelative');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

String _projectionMarkdown({
  required String title,
  required String sourceOfTruthPath,
  required String sourceIdentity,
}) {
  return '''
---
projection_id: projection-test
title: $title
projection_only: true
source_of_truth_paths:
  - $sourceOfTruthPath
editable_draft_blocks:
  - note
---

# $title

- 来源身份：$sourceIdentity
''';
}
