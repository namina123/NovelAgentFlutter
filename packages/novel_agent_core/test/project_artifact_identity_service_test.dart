import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  const service = ProjectArtifactIdentityService();

  test('classifies canonical overview and formal authored assets', () {
    expect(
      service.classify(relativePath: 'premise/project_overview.md').shortLabel,
      '支撑概览',
    );
    expect(
      service.classify(relativePath: 'premise/project_constitution.md').shortLabel,
      '正式前提',
    );
    expect(
      service.classify(relativePath: 'chapters/chapter_01.md').shortLabel,
      '正式正文',
    );
    expect(
      service.classify(relativePath: 'samples/opening_sample.md').shortLabel,
      '样章',
    );
  });

  test('classifies unified narrative and information roots', () {
    expect(
      service.classify(relativePath: 'knowledge/research_note.md').shortLabel,
      '信息资料',
    );
    expect(
      service.classify(relativePath: '.novel_agent/information/research_notes/001.json')
          .shortLabel,
      '信息资料',
    );
    expect(
      service.classify(relativePath: 'sources/original/demo.md').shortLabel,
      '原文归档',
    );
    expect(
      service.classify(relativePath: 'chapters/inherited/continuation/001_demo.md')
          .shortLabel,
      '派生续写',
    );
    expect(
      service.classify(relativePath: 'chapters/inherited/fanfic/001_demo.md')
          .shortLabel,
      '派生同人',
    );
  });

  test('uses user-facing labels for sqlite projection resources', () {
    final identity = service.classify(
      relativePath: 'premise/sqlite_projection/index.md',
    );

    expect(identity.shortLabel, 'SQLite 资源');
    expect(identity.detailLabel, contains('SQLite 资源'));
    expect(identity.detailLabel, isNot(contains('投影')));
  });

  test('keeps compatibility metadata for legacy project brief path', () {
    final identity = service.classify(relativePath: 'premise/project_brief.md');

    expect(identity.shortLabel, '支撑概览');
    expect(identity.isCompatibilityEntry, isTrue);
    expect(identity.detailLabel, contains('兼容入口'));
  });

  test('formats known artifact paths with labels and keeps unknown raw paths', () {
    expect(
      service.formatPathWithLabel('analysis/runtime_audit.md'),
      'analysis/runtime_audit.md（分析资料）',
    );
    expect(
      service.formatPathWithLabel('tracking/long_task_runs/run_01.json'),
      'tracking/long_task_runs/run_01.json',
    );
  });
}
