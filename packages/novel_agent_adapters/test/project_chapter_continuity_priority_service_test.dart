import 'package:novel_agent_adapters/src/workflow/project_chapter_continuity_priority_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectChapterContinuityPriorityService', () {
    const service = ProjectChapterContinuityPriorityService();

    test('把 chapters/ 下带"第N章"的原作正文识别为前情并给正文权重', () {
      // 中文注释: 续写场景规格——拆书分好的正文落在正文区域 chapters/第N章_*.md，
      // 续写第 N+1 章时，第 N 章（前情）应被优先级服务选中并拿到正文权重 1090。
      final weights = service.buildPriorityWeights(
        <JsonMap>[
          <String, Object?>{
            'relative_path': 'chapters/第一章_港口风暴.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'chapters/第二章_议会阴影.md',
            'is_dir': false,
          },
        ],
        taskType: 'chapter',
        chapterLabel: '第2章',
      );

      // 第一章是前情（previousChapterNumber=1），应拿到正文权重 1090。
      expect(weights['chapters/第一章_港口风暴.md'], 1090);
      // 第二章是当前章本身，不作为"前情"入选。
      expect(weights.containsKey('chapters/第二章_议会阴影.md'), isFalse);
    });

    test('不带章节号标记的 chapters/ 文件拿不到前情权重', () {
      // 中文注释: 优先级服务只认路径里能解析出"第N章"的文件；纯文字标题（无章节号）不会入选。
      // 这反向确认了上面那条用例里拿到 1090 是因为"第一章"被解析成了章节号。
      final weights = service.buildPriorityWeights(
        <JsonMap>[
          <String, Object?>{
            'relative_path': 'chapters/港口风暴.md',
            'is_dir': false,
          },
        ],
        taskType: 'chapter',
        chapterLabel: '第2章',
      );

      expect(weights, isEmpty);
    });
  });
}
