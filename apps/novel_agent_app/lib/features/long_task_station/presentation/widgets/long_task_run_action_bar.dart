import 'package:flutter/material.dart';

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () =>
              actionHandler.onLongTaskStationOpenProjectRequested(run.id),
          child: const Text('打开项目'),
        ),
        OutlinedButton(
          onPressed: run.activeTaskPath.trim().isEmpty
              ? null
              : () => actionHandler.onLongTaskStationResourceRequested(
                  run.id,
                  run.activeTaskPath,
                ),
          child: const Text('查看当前任务'),
        ),
        OutlinedButton(
          onPressed: run.canPause
              ? () => actionHandler.onLongTaskStationPauseRequested(run.id)
              : null,
          child: const Text('暂停'),
        ),
        OutlinedButton(
          onPressed: run.canResume
              ? () => actionHandler.onLongTaskStationResumeRequested(run.id)
              : null,
          child: Text(run.resumeActionLabel),
        ),
        OutlinedButton(
          onPressed: run.canStop
              ? () => actionHandler.onLongTaskStationStopRequested(run.id)
              : null,
          child: const Text('停止'),
        ),
      ],
    );
  }
}
