import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('projects structured review report into chapter analysis result', () {
    final service = ReviewReportChapterAnalysisProjectionService();

    final result = service.project(
      <String, Object?>{
        'id': 'review_plot_01',
        'review_type': 'plot',
        'title': '第一章剧情审稿',
        'scope': 'chapters/ch01.md',
        'summary': '前半段冲突进入过慢。',
        'issues': <Object?>[
          <String, Object?>{
            'title': '冲突启动偏慢',
            'severity': 'high',
            'suggestion': '把短信节点提前到开篇。',
            'source_path': 'chapters/ch01.md',
            'start_line': 1,
            'end_line': 14,
          },
        ],
        'suggestions': <Object?>['收紧说明段，增加动作推进。'],
        'source_paths': <Object?>['chapters/ch01.md'],
      },
      reportPath: 'reviews/plot/ch01.md',
    );

    expect(result.id, 'review_plot_01');
    expect(result.analysisType, 'plot');
    expect(result.issues, hasLength(1));
    expect(result.suggestions, hasLength(2));
    expect(result.suggestions.first.actionKind, ChapterRewriteActionKind.rewritePartial);
    expect(result.suggestions.first.targetSegments.single.startLine, 1);
    expect(result.suggestions.last.actionKind, ChapterRewriteActionKind.suggestionsOnly);
    expect(result.metadata['review_report_path'], 'reviews/plot/ch01.md');
  });
}
