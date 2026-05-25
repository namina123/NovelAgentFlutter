import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExposurePolicyService', () {
    test('filters transport tools from desktop exposure too', () {
      // 中文注释: 传输层工具即使在桌面端存在，也不能直接暴露给模型 schema。
      const service = ToolExposurePolicyService();

      final exposed = service.filterExposedToolIds(<String>[
        'read_project_file',
        'request_gateway_tool',
      ], hostPlatform: HostPlatform.windows);

      expect(exposed, contains('read_project_file'));
      expect(exposed, isNot(contains('request_gateway_tool')));
    });

    test('keeps project scoped tools on mobile', () {
      // 中文注释: 移动端仍应继续暴露纯项目内工具，不能因为平台过滤把正常能力一并砍掉。
      const service = ToolExposurePolicyService();

      final exposed = service.filterExposedToolIds(<String>[
        'list_project_files',
        'read_project_file',
      ], hostPlatform: HostPlatform.android);

      expect(exposed, <String>['list_project_files', 'read_project_file']);
    });
  });
}
