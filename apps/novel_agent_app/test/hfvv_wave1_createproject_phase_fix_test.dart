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

  // 中文注释: 实测发现 kb 项目 workbench 会话卡在"正在恢复会话..."，导致 lane C/D/E 查询超时。
  // novel 同路径秒完成；已用二分证明 sqlite 会话扫描(listEntries/readTextFile/listPending)全部
  // 有界且快（40-80ms），所以根因不是 I/O 阻塞，而是 kb 延迟水合(deferHydration)的 token/阶段
  // 完成逻辑——精确触发点需运行时追踪。此处用 skip 标记作为回归锚点，待修复后取消 skip。
  test(
    'knowledge_base conversation hydration settles (KNOWN ISSUE: lane C/D/E)',
    () async {
      final apiConfig = const ProbeApiConfig(
        baseUrl: 'https://placeholder.invalid/v1',
        apiKey: 'placeholder',
        modelId: 'placeholder',
        sourceLabel: 'fix_smoke',
      );
      final harness = await HfvvWave1AppShellHarness.create(
        runId: 'diag_kb',
        laneId: 'diag_kb',
        apiConfig: apiConfig,
      );
      try {
        await harness.createProject(
          title: '诊断 kb',
          projectTypeId: 'knowledge_base',
        );
        final statuses = <String>[];
        for (var i = 0; i < 20; i += 1) {
          statuses.add(harness.conversation.generationStatus);
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        expect(
          statuses.last.contains('恢复会话'),
          isFalse,
          reason:
              'knowledge_base 会话水合卡在"正在恢复会话..."——'
              'lane C/D/E 查询超时的根因。详见 '
              'docs/important/real-usage-viewmodel-test-2026-06-23.md。',
        );
      } finally {
        harness.controller.dispose();
      }
    },
    timeout: const Timeout(Duration(seconds: 120)),
    skip:
        '已知缺陷：kb 延迟水合(deferHydration)会话恢复阶段不完成，'
        'listEntries/readTextFile/listPending 均已证有界快速，根因在水合 token/阶段完成逻辑，'
        '待运行时追踪定位后修复。',
  );
}
