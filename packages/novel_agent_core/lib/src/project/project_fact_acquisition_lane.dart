import '../common/json_types.dart';
import '../common/value_readers.dart';

class ProjectFactAcquisitionLane {
  const ProjectFactAcquisitionLane({
    required this.statusId,
    required this.title,
    required this.description,
    this.allowedActions = const <String>[],
    this.forbiddenActions = const <String>[],
  });

  final String statusId;
  final String title;
  final String description;
  final List<String> allowedActions;
  final List<String> forbiddenActions;

  JsonMap toJsonMap() {
    return <String, Object?>{
      'status_id': statusId,
      'title': title,
      'description': description,
      'allowed_actions': ValueReaders.deepCopyList(
        allowedActions.cast<Object?>(),
      ),
      'forbidden_actions': ValueReaders.deepCopyList(
        forbiddenActions.cast<Object?>(),
      ),
    };
  }
}
