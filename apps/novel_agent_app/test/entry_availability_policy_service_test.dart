import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/shared/models/entry_availability.dart';
import 'package:novel_agent_app/shared/services/entry_availability_policy_service.dart';

void main() {
  const service = EntryAvailabilityPolicyService();

  test('长任务启动在宿主未接线时保持隐藏且不暴露用户理由', () {
    final decision = service.longTaskStart(
      hostWired: false,
      entryRelevant: true,
      ready: true,
      userReason: '这段文案不应对用户可见。',
      diagnosticReason: '当前宿主尚未接入长任务启动执行器。',
    );

    expect(decision.entryId, 'opening.start_long_task_run');
    expect(decision.state, EntryAvailabilityState.hidden);
    expect(decision.isHidden, isTrue);
    expect(decision.userReason, isEmpty);
    expect(decision.shouldShowUserReason, isFalse);
    expect(decision.diagnosticReason, contains('长任务启动执行器'));
  });

  test('拆书派生项目创建在用户条件不足时保持可见但禁用', () {
    final decision = service.derivedProjectCreation(
      hostWired: true,
      entryRelevant: true,
      ready: false,
      userReason: '请先补齐拆书预览并配置派生项目根目录。',
      diagnosticReason: 'book_deconstruction.create_derived_project.unready',
    );

    expect(decision.entryId, 'book_deconstruction.create_derived_project');
    expect(decision.state, EntryAvailabilityState.disabledWithUserReason);
    expect(decision.isDisabledWithUserReason, isTrue);
    expect(decision.shouldShowUserReason, isTrue);
    expect(decision.userReason, contains('派生项目根目录'));
    expect(decision.diagnosticReason, contains('unready'));
  });

  test('项目类型转换在条件齐备时可直接开放', () {
    final decision = service.projectTypeTransition(
      hostWired: true,
      entryRelevant: true,
      ready: true,
      diagnosticReason: 'workspace.transition_project_type.ready',
    );

    expect(decision.entryId, 'workspace.transition_project_type');
    expect(decision.state, EntryAvailabilityState.available);
    expect(decision.isAvailable, isTrue);
    expect(decision.userReason, isEmpty);
    expect(decision.hasDiagnosticReason, isTrue);
  });

  test('项目类型转换在入口不适用时会隐藏而不是给出伪禁用态', () {
    final decision = service.projectTypeTransition(
      hostWired: true,
      entryRelevant: false,
      ready: false,
      userReason: '不应展示给用户。',
      diagnosticReason: 'workspace.transition_project_type.not_applicable',
    );

    expect(decision.state, EntryAvailabilityState.hidden);
    expect(decision.userReason, isEmpty);
    expect(decision.diagnosticReason, contains('not_applicable'));
  });
}
