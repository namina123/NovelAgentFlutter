import 'task_center_contract_action_view_data.dart';

class TaskCenterActionGroupViewData {
  const TaskCenterActionGroupViewData({
    required this.id,
    required this.title,
    required this.summary,
    required this.actions,
  });

  final String id;
  final String title;
  final String summary;
  final List<TaskCenterContractActionViewData> actions;
}
