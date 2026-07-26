import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectWorkflowReviewerDispatchService', () {
    test('projects core collaboration contract reviewer result', () {
      final service = ProjectWorkflowReviewerDispatchService();
      final result = service.resolve(
        task: const <String, Object?>{'task_type': 'review'},
        mainAgent: const <String, Object?>{
          'id': 'writer',
          'name': '作者',
          'role': '负责正文',
        },
        selectedCollaborationGroup: const <String, Object?>{
          'id': 'writer_room',
          'agents': <String>['writer'],
          'primary_agent_id': 'writer',
        },
        availableAgents: const <JsonMap>[
          <String, Object?>{'id': 'writer', 'name': '作者', 'role': '负责正文'},
        ],
        availableGroups: const <JsonMap>[],
      );

      expect(
        ValueReaders.stringValue(result['review_execution_mode']),
        'self_review',
      );
      expect(
        ValueReaders.stringValue(result['selection_mode']),
        ReviewerSelectionModes.primaryWriterSelfReview,
      );
      expect(ValueReaders.stringValue(result['agent_id']), 'writer');
    });
  });
}
