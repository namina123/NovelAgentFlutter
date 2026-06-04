import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Open narrative state namespace scaffolding', () {
    test('top-level package export exposes lightweight ONS-02 types', () {
      const NarrativeStateNamespace claimNamespace = 'project.main';
      const NarrativeStateSchemaVersion schemaVersion = 'ons-02-smoke';
      const NarrativeStateRecordId recordId = 'claim-001';
      const ContextActivationId activationId = 'activation-001';
      const ContextActivationSource activationSource = 'continuity_projection';
      const ContextActivationReasonCode reasonCode = 'chapter_context';
      const DomainToolName domainToolName = 'submit_chapter_delivery';
      const DomainToolSchemaVersion domainSchemaVersion = 'ons-02-smoke';
      const DomainToolCallId domainToolCallId = 'tool-call-001';

      expect(claimNamespace, 'project.main');
      expect(schemaVersion, 'ons-02-smoke');
      expect(recordId, 'claim-001');
      expect(activationId, 'activation-001');
      expect(activationSource, 'continuity_projection');
      expect(reasonCode, 'chapter_context');
      expect(domainToolName, 'submit_chapter_delivery');
      expect(domainSchemaVersion, 'ons-02-smoke');
      expect(domainToolCallId, 'tool-call-001');
    });
  });
}
