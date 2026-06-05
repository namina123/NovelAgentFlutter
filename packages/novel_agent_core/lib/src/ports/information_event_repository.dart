import '../information/information_event.dart';
import '../project/project_descriptor.dart';

abstract class InformationEventRepository {
  Future<void> appendInformationEvent(
    ProjectDescriptor project,
    InformationEvent event,
  );

  Future<InformationEvent?> readInformationEvent(
    ProjectDescriptor project, {
    required String eventId,
  });

  Future<List<InformationEvent>> listInformationEvents(
    ProjectDescriptor project, {
    String? eventType,
    String? lifecycleStatus,
    String? subjectRefId,
  });

  Future<void> updateInformationEvent(
    ProjectDescriptor project,
    InformationEvent event,
  );
}
