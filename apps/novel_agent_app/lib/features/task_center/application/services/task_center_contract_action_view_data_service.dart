import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/task_center_action_group_view_data.dart';
import '../../presentation/models/task_center_contract_action_view_data.dart';

class TaskCenterContractActionViewDataService {
  const TaskCenterContractActionViewDataService();

  List<TaskCenterActionGroupViewData> buildGroups({
    JsonMap checkpointActionPackage = const <String, Object?>{},
    JsonMap revisionResolution = const <String, Object?>{},
  }) {
    // 中文注释: 共享动作包到 GUI 视图数据的映射统一集中在这里，避免控制器和 widget 直接处理 runtime 合同细节。
    final groups = <TaskCenterActionGroupViewData>[];
    final checkpointGroup = _checkpointGroup(checkpointActionPackage);
    if (checkpointGroup != null) {
      groups.add(checkpointGroup);
    }
    final revisionGroup = _revisionGroup(revisionResolution);
    if (revisionGroup != null) {
      groups.add(revisionGroup);
    }
    return List<TaskCenterActionGroupViewData>.unmodifiable(groups);
  }

  TaskCenterActionGroupViewData? _checkpointGroup(JsonMap actionPackage) {
    if (!ValueReaders.boolValue(actionPackage['ok'])) {
      return null;
    }
    final review = ValueReaders.mapValue(actionPackage['review']);
    final task = ValueReaders.mapValue(review['task']);
    final checkpointReviewPath = ValueReaders.stringValue(
      actionPackage['checkpoint_review_path'],
    ).trim();
    final ownerTaskPath = ValueReaders.stringValue(
      task['relative_path'],
    ).trim();
    final actions = ValueReaders.mapList(actionPackage['actions'])
        .map(
          (action) => _mapAction(
            action,
            recommendedActionId: ValueReaders.stringValue(
              actionPackage['recommended_action_id'],
            ),
            invocationKind: 'checkpoint_review',
            ownerTaskPath: ownerTaskPath,
            checkpointReviewPath: checkpointReviewPath,
          ),
        )
        .whereType<TaskCenterContractActionViewData>()
        .toList(growable: false);
    if (actions.isEmpty) {
      return null;
    }
    return TaskCenterActionGroupViewData(
      id: 'checkpoint_review',
      title:
          '检查点动作｜${ValueReaders.stringValue(actionPackage['severity_label'], '风险未评估')}',
      summary: ValueReaders.stringValue(actionPackage['action_summary']),
      actions: actions,
    );
  }

  TaskCenterActionGroupViewData? _revisionGroup(JsonMap resolution) {
    if (!ValueReaders.boolValue(resolution['ok'])) {
      return null;
    }
    final task = ValueReaders.mapValue(resolution['task']);
    final ownerTaskPath = ValueReaders.stringValue(
      task['relative_path'],
    ).trim();
    final checkpointReviewPath = ValueReaders.stringValue(
      resolution['checkpoint_review_path'],
    ).trim();
    final actions = ValueReaders.mapList(resolution['actions'])
        .map(
          (action) => _mapAction(
            action,
            recommendedActionId: '',
            invocationKind: 'revision_resolution',
            ownerTaskPath: ownerTaskPath,
            checkpointReviewPath: checkpointReviewPath,
          ),
        )
        .whereType<TaskCenterContractActionViewData>()
        .toList(growable: false);
    if (actions.isEmpty) {
      return null;
    }
    return TaskCenterActionGroupViewData(
      id: 'revision_resolution',
      title:
          '修订收口｜${ValueReaders.stringValue(resolution['stage_label'], '处理中')}',
      summary: ValueReaders.stringValue(resolution['action_summary']),
      actions: actions,
    );
  }

  TaskCenterContractActionViewData? _mapAction(
    JsonMap action, {
    required String recommendedActionId,
    required String invocationKind,
    required String ownerTaskPath,
    required String checkpointReviewPath,
  }) {
    final id = ValueReaders.stringValue(action['id']).trim();
    if (id.isEmpty) {
      return null;
    }
    final hostCommand = ValueReaders.stringValue(action['host_command']).trim();
    final supported = _isMaterialized(
      invocationKind: invocationKind,
      hostCommand: hostCommand,
    );
    final enabled = ValueReaders.boolValue(action['enabled']) && supported;
    final disabledReason = !supported
        ? '当前图形界面还未接通该建议动作。'
        : ValueReaders.stringValue(action['disabled_reason']);
    return TaskCenterContractActionViewData(
      id: id,
      label: ValueReaders.stringValue(action['label'], id),
      note: ValueReaders.stringValue(action['note']),
      tone: ValueReaders.stringValue(action['tone'], 'neutral'),
      invocationKind: invocationKind,
      enabled: enabled,
      disabledReason: enabled ? '' : disabledReason,
      ownerTaskPath: ownerTaskPath,
      checkpointReviewPath: checkpointReviewPath,
      isRecommended:
          recommendedActionId.trim().isNotEmpty &&
          recommendedActionId.trim() == id,
    );
  }

  bool _isMaterialized({
    required String invocationKind,
    required String hostCommand,
  }) {
    // 中文注释: 只把已经真正接到宿主执行链的动作按钮开放出来，其他合同先展示但不允许误点。
    if (invocationKind == 'checkpoint_review') {
      return hostCommand == 'apply_checkpoint_review_action';
    }
    if (invocationKind == 'revision_resolution') {
      return hostCommand == 'apply_revision_resolution_action';
    }
    return false;
  }
}
