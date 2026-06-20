import 'package:test/test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'knowledge base branches open into their intended primary workspace',
    () {
      const catalog = KnowledgeBaseBranchCatalogService();

      final structured = catalog.definitionOf(
        KnowledgeBaseBranchCatalogService.structuredBranchId,
      );
      final rag = catalog.definitionOf(
        KnowledgeBaseBranchCatalogService.ragBranchId,
      );

      expect(structured.opensProjectAssetsByDefault, isTrue);
      expect(structured.preferredAssetsTabId, 'reference_extraction');
      expect(rag.opensProjectAssetsByDefault, isTrue);
      expect(rag.preferredAssetsTabId, 'rag_extraction');
    },
  );
}
