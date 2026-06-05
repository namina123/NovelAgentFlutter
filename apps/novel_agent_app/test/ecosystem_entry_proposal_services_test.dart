import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/ecosystem_entry_creation_plan_service.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/ecosystem_entry_editor_service.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/ecosystem_editor_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('editor save plan writes non-builtin skill as proposal record', () {
    final service = EcosystemEntryEditorService();
    final plan = service.buildSavePlan(
      const EcosystemEditorRequestViewData(
        kind: 'skills',
        originalEntryId: 'demo-skill',
        originalRelativePath: 'skills/demo-skill/SKILL.md',
        entryId: 'demo-skill',
        name: '示例技能',
        description: '整理项目资料。',
        role: '',
        objective: '',
        bodyMarkdown: '# 示例技能\n\n先整理资料。',
        skillsText: '',
        skillGroupsText: '',
        agentsText: '',
        activationHintsText: '',
        inputsText: '',
        outputsText: '',
        canDoText: '',
        mustNotDoText: '',
        knowledgeSourcesText: '',
        requiredCapabilitiesText: 'project_read',
        optionalCapabilitiesText: '',
        preferredOutput: '',
        orchestration: 'supervised',
        enabled: false,
      ),
    );
    final proposal = EcosystemAssetProposal.fromJson(
      ValueReaders.mapValue(jsonDecode(plan.content)),
    );

    expect(
      plan.relativePath,
      startsWith('.novel_agent/ecosystem/proposals/skill/'),
    );
    expect(plan.deleteOldRelativePath, isFalse);
    expect(proposal.proposalStatus, EcosystemAssetLifecycleStatus.validated);
    expect(proposal.assetKind, EcosystemAssetKind.skill);
    expect(proposal.riskNote, contains('不会自动授予高风险权限'));
  });

  test(
    'creation plan scaffolds new agent as proposal instead of installed file',
    () {
      final service = EcosystemEntryCreationPlanService();
      final plan = service.createPlan('agents');
      final proposal = EcosystemAssetProposal.fromJson(
        ValueReaders.mapValue(jsonDecode(plan.content)),
      );

      expect(
        plan.relativePath,
        startsWith('.novel_agent/ecosystem/proposals/agent/'),
      );
      expect(proposal.assetKind, EcosystemAssetKind.agent);
      expect(
        proposal.proposalStatus,
        anyOf(
          EcosystemAssetLifecycleStatus.proposal,
          EcosystemAssetLifecycleStatus.validated,
        ),
      );
    },
  );

  test(
    'editor save plan clones builtin agent-group into proposal with primary and scoped members',
    () {
      final service = EcosystemEntryEditorService();
      final plan = service.buildSavePlan(
        const EcosystemEditorRequestViewData(
          kind: 'agent-groups',
          originalEntryId: 'builtin_review_room',
          originalRelativePath: '',
          entryId: 'builtin_review_room_copy',
          name: '项目审稿室',
          description: '复制内置协作组后调整主次关系。',
          role: '',
          objective: '',
          bodyMarkdown: '',
          skillsText: '',
          skillGroupsText: '',
          agentsText: 'default_generalist\nreader_lens\ncontinuity_sentinel',
          activationHintsText: '',
          inputsText: '',
          outputsText: '',
          canDoText: '',
          mustNotDoText: '',
          knowledgeSourcesText: '',
          requiredCapabilitiesText: '',
          optionalCapabilitiesText: '',
          preferredOutput: '',
          orchestration: 'supervised',
          enabled: true,
          primaryAgentIdText: 'reader_lens',
          requiredAgentIdsText: 'default_generalist\nreader_lens',
          optionalAgentIdsText: 'continuity_sentinel',
        ),
      );
      final proposal = EcosystemAssetProposal.fromJson(
        ValueReaders.mapValue(jsonDecode(plan.content)),
      );
      final payload = proposal.assetPayload;

      expect(
        plan.relativePath,
        startsWith('.novel_agent/ecosystem/proposals/agent-group/'),
      );
      expect(proposal.assetKind, EcosystemAssetKind.agentGroup);
      expect(
        ValueReaders.stringValue(payload['primary_agent_id']),
        'reader_lens',
      );
      expect(ValueReaders.stringList(payload['required_agent_ids']), <String>[
        'default_generalist',
        'reader_lens',
      ]);
      expect(ValueReaders.stringList(payload['optional_agent_ids']), <String>[
        'continuity_sentinel',
      ]);
      expect(
        ValueReaders.mapValue(payload['member_roles'])['reader_lens'],
        'primary',
      );
    },
  );
}
