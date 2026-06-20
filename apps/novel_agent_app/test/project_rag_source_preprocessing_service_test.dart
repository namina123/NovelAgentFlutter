import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_rag_source_preprocessing_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'offline preprocess cleans noisy lines into normalized source text',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'project_rag_source_preprocessing_service_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample.txt',
      );
      await sourceFile.writeAsString('''
最新网址：www.example.com
第一章
正文第一段。

广告
第二章
正文第二段。
''');

      final service = ProjectRagSourcePreprocessingService();
      final result = await service.preprocess(
        project: ProjectDescriptor(
          id: 'rag-preprocess-project',
          name: '语料项目',
          rootPath: tempDirectory.path,
          projectType: 'knowledge_base',
          projectBranchId: KnowledgeBaseBranchCatalogService.ragBranchId,
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
        sourcePaths: <String>[sourceFile.path],
      );

      expect(result.ok, isTrue);
      expect(result.usedSmartNormalization, isFalse);
      expect(result.normalizedSourceText, contains('第一章'));
      expect(result.normalizedSourceText, contains('第二章'));
      expect(result.normalizedSourceText, isNot(contains('广告')));
      expect(result.normalizedSourceText, isNot(contains('最新网址')));
    },
  );
}
