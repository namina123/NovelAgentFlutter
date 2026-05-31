import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_preview_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/sub_agent_run_preview_projection_service.dart';

void main() {
  group('SubAgentRunPreviewProjectionService', () {
    const service = SubAgentRunPreviewProjectionService();

    test('projects running state and falls back to latest event summary', () {
      const run = SubAgentRunViewData(
        id: 'sub_1',
        agentName: '角色整理员',
        task: '补齐角色约束',
        status: '运行中',
        summary: '',
        content: '',
        reasoning: '',
        toolCount: 3,
        events: ['开始委派', '正在核对角色卡'],
      );

      final preview = service.build(run);

      expect(preview.statusTone, SubAgentRunPreviewTone.active);
      expect(preview.isRunning, isTrue);
      expect(preview.summaryPreview, '正在核对角色卡');
    });

    test('projects failure state from status text', () {
      const run = SubAgentRunViewData(
        id: 'sub_2',
        agentName: '伏笔检查员',
        task: '核对伏笔回收',
        status: '失败',
        summary: '上下文不足。',
        content: '',
        reasoning: '',
        toolCount: 1,
        events: [],
      );

      final preview = service.build(run);

      expect(preview.statusTone, SubAgentRunPreviewTone.danger);
      expect(preview.summaryPreview, '上下文不足。');
    });
  });
}
