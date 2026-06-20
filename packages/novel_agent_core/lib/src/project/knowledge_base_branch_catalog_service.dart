import 'knowledge_base_branch_definition.dart';

class KnowledgeBaseBranchCatalogService {
  const KnowledgeBaseBranchCatalogService();

  static const String structuredBranchId = 'structured_reference_library';
  static const String ragBranchId = 'rag_corpus_library';

  static const List<KnowledgeBaseBranchDefinition> _definitions =
      <KnowledgeBaseBranchDefinition>[
        KnowledgeBaseBranchDefinition(
          id: structuredBranchId,
          title: '结构化资料库',
          description: '把资料提取为结构化知识、卡片、设计元素和参考记录，适合后续复用、分享与精细检索。',
          opensProjectAssetsByDefault: true,
          preferredAssetsTabId: 'reference_extraction',
        ),
        KnowledgeBaseBranchDefinition(
          id: ragBranchId,
          title: '语料库',
          description: '把资料切分、清洗并构建为可挂载的语料包，适合检索增强和证据型引用，不把它当作正式写作工作区主面板。',
          opensProjectAssetsByDefault: true,
          preferredAssetsTabId: 'rag_extraction',
        ),
      ];

  List<KnowledgeBaseBranchDefinition> definitions() {
    return List<KnowledgeBaseBranchDefinition>.unmodifiable(_definitions);
  }

  bool usesBranchSelection(String projectTypeId) {
    return projectTypeId.trim() == 'knowledge_base';
  }

  String normalize(String projectTypeId, String branchId) {
    if (!usesBranchSelection(projectTypeId)) {
      return '';
    }
    final cleanId = branchId.trim();
    for (final definition in _definitions) {
      if (definition.id == cleanId) {
        return cleanId;
      }
    }
    return structuredBranchId;
  }

  KnowledgeBaseBranchDefinition definitionOf(String branchId) {
    final normalizedId = normalize('knowledge_base', branchId);
    for (final definition in _definitions) {
      if (definition.id == normalizedId) {
        return definition;
      }
    }
    return _definitions.first;
  }

  bool isRagBranch(String branchId) {
    return normalize('knowledge_base', branchId) == ragBranchId;
  }
}
