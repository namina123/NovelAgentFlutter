import 'entry_availability.dart';

class EntryAvailabilityPolicyService {
  const EntryAvailabilityPolicyService();

  EntryAvailabilityDecision longTaskStart({
    required bool hostWired,
    required bool entryRelevant,
    required bool ready,
    String userReason = '',
    String diagnosticReason = '',
  }) {
    // 中文注释: 长任务启动入口先收成统一决策，宿主接线、用户缺口和最终可执行态分别落在不同状态里。
    return _classify(
      entryId: 'opening.start_long_task_run',
      hostWired: hostWired,
      entryRelevant: entryRelevant,
      ready: ready,
      userReason: userReason,
      diagnosticReason: diagnosticReason,
    );
  }

  EntryAvailabilityDecision derivedProjectCreation({
    required bool hostWired,
    required bool entryRelevant,
    required bool ready,
    String userReason = '',
    String diagnosticReason = '',
  }) {
    // 中文注释: 拆书派生项目创建入口同样走统一合同，避免控制器自己拼“未接入”或“缺条件”的判断。
    return _classify(
      entryId: 'book_deconstruction.create_derived_project',
      hostWired: hostWired,
      entryRelevant: entryRelevant,
      ready: ready,
      userReason: userReason,
      diagnosticReason: diagnosticReason,
    );
  }

  EntryAvailabilityDecision projectTypeTransition({
    required bool hostWired,
    required bool entryRelevant,
    required bool ready,
    String userReason = '',
    String diagnosticReason = '',
  }) {
    // 中文注释: 项目类型转换入口也统一投影到同一状态合同，后续 GUI 只需消费状态而不必重复写分支。
    return _classify(
      entryId: 'workspace.transition_project_type',
      hostWired: hostWired,
      entryRelevant: entryRelevant,
      ready: ready,
      userReason: userReason,
      diagnosticReason: diagnosticReason,
    );
  }

  EntryAvailabilityDecision _classify({
    required String entryId,
    required bool hostWired,
    required bool entryRelevant,
    required bool ready,
    required String userReason,
    required String diagnosticReason,
  }) {
    // 中文注释: 统一分类规则只处理状态边界，不在这里猜测业务细节或生成第二套运行逻辑。
    if (!hostWired) {
      return EntryAvailabilityDecision.hidden(
        entryId: entryId,
        diagnosticReason: diagnosticReason,
      );
    }
    if (!entryRelevant) {
      return EntryAvailabilityDecision.hidden(
        entryId: entryId,
        diagnosticReason: diagnosticReason,
      );
    }
    if (!ready) {
      return EntryAvailabilityDecision.disabledWithUserReason(
        entryId: entryId,
        userReason: userReason,
        diagnosticReason: diagnosticReason,
      );
    }
    return EntryAvailabilityDecision.available(
      entryId: entryId,
      diagnosticReason: diagnosticReason,
    );
  }
}
