import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuityFoundationBuildCatalogService', () {
    const service = ContinuityFoundationBuildCatalogService();

    test('exposes the three formal continuation foundation specs', () {
      final specs = service.builtinSpecs(
        focusScopeIds: const <String>['global', 'world_main'],
        focusFrameId: 'mainline',
      );

      expect(specs.map((item) => item.id), <String>[
        'quick_bridge',
        'standard_foundation',
        'deep_reconstruction',
      ]);

      final quick = specs[0];
      final standard = specs[1];
      final deep = specs[2];

      expect(quick.tier, ContinuityBuildTier.quickBridge);
      expect(quick.requestedOutputs, <ContinuityBuildOutputKind>[
        ContinuityBuildOutputKind.tailBridge,
        ContinuityBuildOutputKind.stateTables,
      ]);
      expect(
        quick.preferredRuntimeHost,
        ContinuityBuildRuntimeHost.directExecution,
      );

      expect(standard.tier, ContinuityBuildTier.standardFoundation);
      expect(standard.recommended, isTrue);
      expect(standard.requestedOutputs, <ContinuityBuildOutputKind>[
        ContinuityBuildOutputKind.tailBridge,
        ContinuityBuildOutputKind.globalBible,
        ContinuityBuildOutputKind.stageSummaries,
        ContinuityBuildOutputKind.stateTables,
      ]);
      expect(
        standard.preferredRuntimeHost,
        ContinuityBuildRuntimeHost.resumableWorkflowEngine,
      );

      expect(deep.tier, ContinuityBuildTier.deepReconstruction);
      expect(deep.requestedOutputs, <ContinuityBuildOutputKind>[
        ContinuityBuildOutputKind.tailBridge,
        ContinuityBuildOutputKind.globalBible,
        ContinuityBuildOutputKind.stageSummaries,
        ContinuityBuildOutputKind.stateTables,
        ContinuityBuildOutputKind.conflictGapAnalysis,
      ]);
      expect(deep.focusScopeIds, <String>['global', 'world_main']);
      expect(deep.focusFrameId, 'mainline');
    });

    test('builds a formal preview confirm build publish flow contract', () {
      final standard = service.specOfTier(
        ContinuityBuildTier.standardFoundation,
      );
      final flow = service.buildFlowFor(standard);

      expect(flow.id, 'continuation_foundation_build');
      expect(flow.displayName, '续写基座构建');
      expect(
        flow.runtimeHost,
        ContinuityBuildRuntimeHost.resumableWorkflowEngine,
      );
      expect(flow.supportsStepRetry, isTrue);
      expect(flow.supportsPartialArtifacts, isTrue);
      expect(
        flow.stages.map((item) => item.kind),
        <ContinuityFoundationBuildStageKind>[
          ContinuityFoundationBuildStageKind.preview,
          ContinuityFoundationBuildStageKind.confirm,
          ContinuityFoundationBuildStageKind.build,
          ContinuityFoundationBuildStageKind.publish,
        ],
      );
      expect(flow.stages[1].requiresUserInput, isTrue);
      expect(flow.stages[2].buildsArtifacts, isTrue);
      expect(flow.stages[3].publishesArtifacts, isTrue);
    });
  });
}
