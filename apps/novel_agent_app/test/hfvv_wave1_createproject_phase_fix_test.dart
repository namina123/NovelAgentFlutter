// 中文注释: 聚焦验证 createProject 阶段树修复——knowledge_base 项目类型过去在 harness 里
// 卡在 knowledgeBaseBranch 阶段（且误传 markdown 存储给仅支持 sqlite 的类型）。这里只测创建
// 向导本身，不触发 LLM，快速回归。
import 'package:flutter_test/flutter_test.dart';
import '../tool/hfvv_wave1_viewmodel_support.dart';
import '../tool/probe_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'createProject walks knowledge_base branch + coerces sqlite storage',
    () async {
      // 中文注释: 用占位 apiConfig——createProject 只驱动向导，不联网。
      final apiConfig = const ProbeApiConfig(
        baseUrl: 'https://placeholder.invalid/v1',
        apiKey: 'placeholder',
        modelId: 'placeholder',
        sourceLabel: 'fix_smoke',
      );
      final harness = await HfvvWave1AppShellHarness.create(
        runId: 'fix_smoke_kb',
        laneId: 'fix_smoke_kb',
        apiConfig: apiConfig,
      );
      try {
        await harness.createProject(
          title: '修复冒烟 知识库',
          projectTypeId: 'knowledge_base',
        );
        // 中文注释: 创建成功即 projectPath 落地且工作区加载完成（createProject 内部已等待 load settle）。
        expect(harness.workbench.projectPath, isNotEmpty);
        expect(harness.workbench.projectName, '修复冒烟 知识库');
      } finally {
        harness.controller.dispose();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'createProject still works for plain novel type (no regression)',
    () async {
      final apiConfig = const ProbeApiConfig(
        baseUrl: 'https://placeholder.invalid/v1',
        apiKey: 'placeholder',
        modelId: 'placeholder',
        sourceLabel: 'fix_smoke',
      );
      final harness = await HfvvWave1AppShellHarness.create(
        runId: 'fix_smoke_novel',
        laneId: 'fix_smoke_novel',
        apiConfig: apiConfig,
      );
      try {
        await harness.createProject(
          title: '修复冒烟 普通',
          projectTypeId: 'novel',
        );
        expect(harness.workbench.projectPath, isNotEmpty);
      } finally {
        harness.controller.dispose();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
