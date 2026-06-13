import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/primary_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';

PrimaryActionViewData? chooseWave2OpeningPrimaryAction(
  List<PrimaryActionViewData> actions,
) {
  const preferredCommands = <String>[
    'opening.start_long_task_run',
    'guide.create_workflow_from_mode_guidance',
    'guide.answer_mode_guidance',
    'opening.continue_mode_guidance',
    'opening.open_mode_guidance',
    'guide.open_mode_guidance',
    'opening.launch_long_task',
  ];
  for (final commandId in preferredCommands) {
    for (final action in actions) {
      if (action.commandId.trim() == commandId) {
        return action;
      }
    }
  }
  return actions.isEmpty ? null : actions.first;
}

TaskCenterContractActionViewData? chooseWave2TaskCenterSharedAction(
  Iterable<TaskCenterContractActionViewData> actions,
) {
  final enabled = actions
      .where((action) => action.enabled)
      .toList(growable: false);
  if (enabled.isEmpty) {
    return null;
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'task_user_option') {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'checkpoint_review' &&
        action.isRecommended) {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'revision_resolution' &&
        action.isRecommended) {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'run_center_control' &&
        action.id.trim() == 'confirm_checkpoint') {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'checkpoint_review') {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'revision_resolution') {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'run_center_control' &&
        action.id.trim() == 'retry_failed') {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.invocationKind.trim() == 'run_center_control' &&
        action.id.trim() == 'resume') {
      return action;
    }
  }
  for (final action in enabled) {
    if (action.isRecommended) {
      return action;
    }
  }
  final nonGenericRunControls = enabled
      .where(
        (action) =>
            action.invocationKind.trim() != 'run_center_control' ||
            <String>{
              'confirm_checkpoint',
              'retry_failed',
              'resume',
            }.contains(action.id.trim()),
      )
      .toList(growable: false);
  if (nonGenericRunControls.isNotEmpty) {
    return nonGenericRunControls.first;
  }
  return null;
}

UserOptionViewData? chooseLaneFFanficPendingOption(
  List<UserOptionViewData> options,
) {
  const preferredKeywords = <String>[
    '先整理世界观',
    '先列知识卡',
    '先做开局方案',
    '先定主角',
    '先确认偏移',
  ];
  for (final keyword in preferredKeywords) {
    for (final option in options) {
      final text = '${option.label} ${option.description} ${option.prompt}';
      if (text.contains(keyword)) {
        return option;
      }
    }
  }
  return options.isEmpty ? null : options.first;
}
