import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_side_panel_contract_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_navigation_panel_id.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_side_panel_entry_kind.dart';

void main() {
  group('WorkbenchSidePanelContractService', () {
    const service = WorkbenchSidePanelContractService();

    test('defines exactly four object panels in stable order', () {
      final contracts = service.contracts();

      expect(
        contracts.map((item) => item.panelId).toList(growable: false),
        <WorkbenchNavigationPanelId>[
          WorkbenchNavigationPanelId.files,
          WorkbenchNavigationPanelId.project,
          WorkbenchNavigationPanelId.agent,
        ],
      );
    });

    test(
      'files panel only accepts file actions and rejects cross-domain entries',
      () {
        final contract = service.contractOf(WorkbenchNavigationPanelId.files);

        expect(
          contract.supportsEntryKind(WorkbenchSidePanelEntryKind.fileOperation),
          isTrue,
        );
        expect(
          contract.rejectsEntryKind(
            WorkbenchSidePanelEntryKind.projectScopedConfiguration,
          ),
          isTrue,
        );
        expect(
          contract.rejectsEntryKind(
            WorkbenchSidePanelEntryKind.systemCenterEntry,
          ),
          isTrue,
        );
        expect(
          contract.rejectsEntryKind(
            WorkbenchSidePanelEntryKind.projectAgnosticEntry,
          ),
          isTrue,
        );
      },
    );

    test('project panel rejects system centers and pure jump entries', () {
      final contract = service.contractOf(WorkbenchNavigationPanelId.project);

      expect(
        contract.supportsEntryKind(WorkbenchSidePanelEntryKind.projectSummary),
        isTrue,
      );
      expect(
        contract.supportsEntryKind(
          WorkbenchSidePanelEntryKind.projectScopedConfiguration,
        ),
        isTrue,
      );
      expect(
        contract.rejectsEntryKind(
          WorkbenchSidePanelEntryKind.systemCenterEntry,
        ),
        isTrue,
      );
      expect(
        contract.rejectsEntryKind(
          WorkbenchSidePanelEntryKind.projectAgnosticEntry,
        ),
        isTrue,
      );
      expect(
        contract.rejectsEntryKind(WorkbenchSidePanelEntryKind.jumpOnlyEntry),
        isTrue,
      );
    });

    test(
      'agent panel accepts conversation agent summary and project baseline only',
      () {
        final contract = service.contractOf(WorkbenchNavigationPanelId.agent);

        expect(
          contract.supportsEntryKind(
            WorkbenchSidePanelEntryKind.conversationAgentSummary,
          ),
          isTrue,
        );
        expect(
          contract.supportsEntryKind(
            WorkbenchSidePanelEntryKind.projectScopedConfiguration,
          ),
          isTrue,
        );
        expect(
          contract.rejectsEntryKind(WorkbenchSidePanelEntryKind.fileOperation),
          isTrue,
        );
        expect(
          contract.rejectsEntryKind(
            WorkbenchSidePanelEntryKind.longTaskSummary,
          ),
          isTrue,
        );
        expect(
          contract.rejectsEntryKind(WorkbenchSidePanelEntryKind.jumpOnlyEntry),
          isTrue,
        );
      },
    );
  });
}
