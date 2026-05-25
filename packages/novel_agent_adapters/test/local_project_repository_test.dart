import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalProjectRepository', () {
    test('openByPath reads runtime baseline from manifest', () async {
      // 中文注释: 这里验证项目重新打开时会把创建阶段选定的运行基准一并识别回来，而不是只读标题和类型。
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-local-project-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}long-project',
        )..createSync(recursive: true);
        final manifestFile = File(
          '${projectRoot.path}${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}',
        )..createSync(recursive: true);
        final manifest = ProjectManifestCodecService().create(
          title: '长篇项目',
          projectType: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
        );
        await manifestFile.writeAsString(
          ProjectManifestCodecService().encode(manifest),
        );

        final repository = LocalProjectRepository();
        final descriptor = await repository.openByPath(projectRoot.path);

        expect(descriptor, isNotNull);
        expect(descriptor!.projectType, 'long_novel');
        expect(descriptor.runtimeBaselineId, 'continuous_autonomous');
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });
  });
}
