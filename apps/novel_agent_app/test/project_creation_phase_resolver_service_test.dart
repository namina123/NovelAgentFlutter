import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_creation_phase_resolver_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const resolver = ProjectCreationPhaseResolverService();

  test('novel default wizard skips storage strategy phase', () {
    final phases = resolver.phasesFor(
      projectTypeId: 'novel',
      requiresRuntimeBaselineSelection: false,
    );
    expect(phases, <ProjectCreationPhase>[ProjectCreationPhase.projectType]);
    expect(
      resolver.defaultStorageStrategy('novel'),
      ProjectStorageStrategy.markdownProjectStore,
    );
  });

  test('long_novel goes type then runtime baseline without storage step', () {
    final phases = resolver.phasesFor(
      projectTypeId: 'long_novel',
      requiresRuntimeBaselineSelection: true,
    );
    expect(phases, <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      ProjectCreationPhase.runtimeBaseline,
    ]);
  });

  test('knowledge_base still has branch phase and never requires storage step',
      () {
    final phases = resolver.phasesFor(
      projectTypeId: 'knowledge_base',
      requiresRuntimeBaselineSelection: false,
    );
    expect(phases, <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      ProjectCreationPhase.knowledgeBaseBranch,
    ]);
    expect(
      resolver.defaultStorageStrategy('knowledge_base'),
      ProjectStorageStrategy.sqliteProjectStore,
    );
  });

  test('advanced flag can re-enable storage phase for multi-strategy types', () {
    final phases = resolver.phasesFor(
      projectTypeId: 'novel',
      requiresRuntimeBaselineSelection: false,
      includeStorageStrategyPhase: true,
    );
    expect(phases, <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      ProjectCreationPhase.storageStrategy,
    ]);
  });
}
