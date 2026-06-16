import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_document_identity_service.dart';

void main() {
  const service = WorkbenchDocumentIdentityService();

  test('classifies support overview and formal assets by path', () {
    expect(
      service.identityLabel(relativePath: 'premise/project_overview.md'),
      '支撑概览',
    );
    expect(
      service.identityLabel(relativePath: 'premise/project_constitution.md'),
      '正式前提',
    );
    expect(
      service.identityLabel(relativePath: 'chapters/chapter_01.md'),
      '正式正文',
    );
    expect(
      service.identityLabel(relativePath: 'premise/sqlite_projection/index.md'),
      'SQLite 投影',
    );
  });

  test(
    'prefers buffered draft identity and unsaved status for recovery drafts',
    () {
      expect(
        service.statusLabel(
          relativePath: 'chapters/chapter_01.md',
          isDirty: true,
          isBufferedDraft: true,
          fallbackStatus: '已打开 chapters/chapter_01.md',
          isRenderMode: false,
          isStructureMode: false,
        ),
        '草稿缓存 · 未正式保存',
      );
      expect(
        service.tooltipLabel(
          relativePath: 'chapters/chapter_01.md',
          title: '第一章',
          isDirty: true,
          isBufferedDraft: true,
        ),
        'chapters/chapter_01.md\n草稿缓存\n尚未正式保存',
      );
    },
  );

  test('exposes plain state labels separately from identity labels', () {
    expect(
      service.stateLabel(
        isDirty: false,
        isBufferedDraft: true,
        fallbackStatus: '已打开 chapters/chapter_01.md',
        isRenderMode: false,
        isStructureMode: false,
      ),
      '未正式保存',
    );
    expect(
      service.stateLabel(
        isDirty: true,
        isBufferedDraft: false,
        fallbackStatus: '',
        isRenderMode: false,
        isStructureMode: false,
      ),
      '未保存修改',
    );
  });
}
