import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../contracts/long_task_station_action_handler.dart';
import '../models/long_task_station_view_data.dart';

class LongTaskRunActionBar extends StatelessWidget {
  const LongTaskRunActionBar({
    super.key,
    required this.run,
    required this.actionHandler,
  });

  final LongTaskRunDetailViewData run;
  final LongTaskStationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 全部改用共享 ActionButton——与任务中心动作网格同一套禁用态视觉
    // (disabled 时前景/边框/背景统一中性弱化)，不再用 Material 默认 OutlinedButton 禁用样式。
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionButton(
          label: '打开项目',
          icon: Icons.folder_open_outlined,
          compact: true,
          tone: ActionButtonTone.neutral,
          onPressed: () =>
              actionHandler.onLongTaskStationOpenProjectRequested(run.id),
        ),
        ActionButton(
          label: '查看当前任务',
          icon: Icons.task_alt_outlined,
          compact: true,
          tone: ActionButtonTone.neutral,
          disabled: run.activeTaskPath.trim().isEmpty,
          onPressed: () => actionHandler.onLongTaskStationResourceRequested(
            run.id,
            run.activeTaskPath,
          ),
        ),
        ActionButton(
          label: '暂停',
          icon: Icons.pause_rounded,
          compact: true,
          tone: ActionButtonTone.neutral,
          disabled: !run.canPause,
          onPressed: () =>
              actionHandler.onLongTaskStationPauseRequested(run.id),
        ),
        ActionButton(
          label: run.resumeActionLabel,
          icon: Icons.play_arrow_rounded,
          compact: true,
          disabled: !run.canResume,
          onPressed: () =>
              actionHandler.onLongTaskStationResumeRequested(run.id),
        ),
        ActionButton(
          // 中文注释: 停止整条运行实例不可逆（未保存中间进度会丢失），二次确认，与任务中心"取消"对称。
          label: '停止',
          icon: Icons.stop_rounded,
          compact: true,
          tone: ActionButtonTone.danger,
          disabled: !run.canStop,
          onPressed: () async {
            final confirmed = await showConfirmationDialog(
              context,
              title: '停止该运行实例？',
              message: '停止后该运行将终止，未保存的中间进度可能丢失；项目本身不受影响。',
              confirmLabel: '停止',
            );
            if (confirmed) {
              actionHandler.onLongTaskStationStopRequested(run.id);
            }
          },
        ),
      ],
    );
  }
}
