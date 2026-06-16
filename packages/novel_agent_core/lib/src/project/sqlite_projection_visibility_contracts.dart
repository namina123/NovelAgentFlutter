import 'project_content_path_policy_service.dart';
import 'project_storage_strategy.dart';
import 'project_workspace_catalog.dart';

enum SqliteProjectionGroupKind {
  projectOverview,
  bodyAndChapters,
  outlineAndSetting,
  projectMaterials,
  referenceMounts,
  importSources,
  extractionAndReview,
  exportAndProjection,
  diagnosticReadOnly,
}

extension SqliteProjectionGroupKindX on SqliteProjectionGroupKind {
  String get label {
    // 中文注释: 分组标签是语义树主入口的稳定文案，后续 adapters/app 直接复用这层而不是重写中文名。
    return switch (this) {
      SqliteProjectionGroupKind.projectOverview => '项目概览',
      SqliteProjectionGroupKind.bodyAndChapters => '正文与章节',
      SqliteProjectionGroupKind.outlineAndSetting => '大纲与设定',
      SqliteProjectionGroupKind.projectMaterials => '项目资料',
      SqliteProjectionGroupKind.referenceMounts => '参考资产挂载',
      SqliteProjectionGroupKind.importSources => '导入源',
      SqliteProjectionGroupKind.extractionAndReview => '提取与审核',
      SqliteProjectionGroupKind.exportAndProjection => '导出与投影',
      SqliteProjectionGroupKind.diagnosticReadOnly => '高级只读诊断',
    };
  }

  String get summary {
    // 中文注释: 分组摘要只描述“这个分区为什么存在”，避免 UI 再单独拼一套解释性文案。
    return switch (this) {
      SqliteProjectionGroupKind.projectOverview => '项目总览、快速入口说明和开局级导览。',
      SqliteProjectionGroupKind.bodyAndChapters => '正文、章节与场景的主可见内容。',
      SqliteProjectionGroupKind.outlineAndSetting => '大纲、设定和结构化创作资产。',
      SqliteProjectionGroupKind.projectMaterials => '项目资料、知识、研究和辅助材料。',
      SqliteProjectionGroupKind.referenceMounts => '来自参考资产库或外部挂载的正式引用资产。',
      SqliteProjectionGroupKind.importSources => '导入中的原始来源与待整理素材。',
      SqliteProjectionGroupKind.extractionAndReview => '提取、审核、校验与回看产物。',
      SqliteProjectionGroupKind.exportAndProjection => '导出包、投影文件和对外交换结果。',
      SqliteProjectionGroupKind.diagnosticReadOnly => '面向高级只读诊断的内部结构与恢复信息。',
    };
  }

  bool get isDiagnosticLayer {
    // 中文注释: 诊断层与主语义树分离，便于 app 在默认树中直接折叠掉高噪声内容。
    return this == SqliteProjectionGroupKind.diagnosticReadOnly;
  }
}

enum SqliteProjectionNodeKind {
  root,
  groupHeader,
  document,
  projection,
  source,
  record,
  attachment,
  diagnostic,
  metadata,
}

extension SqliteProjectionNodeKindX on SqliteProjectionNodeKind {
  String get label {
    // 中文注释: 节点类型标签用于内部投影调试和后续序列化，不把路径语义藏进 UI 侧临时字符串。
    return switch (this) {
      SqliteProjectionNodeKind.root => 'root',
      SqliteProjectionNodeKind.groupHeader => 'group_header',
      SqliteProjectionNodeKind.document => 'document',
      SqliteProjectionNodeKind.projection => 'projection',
      SqliteProjectionNodeKind.source => 'source',
      SqliteProjectionNodeKind.record => 'record',
      SqliteProjectionNodeKind.attachment => 'attachment',
      SqliteProjectionNodeKind.diagnostic => 'diagnostic',
      SqliteProjectionNodeKind.metadata => 'metadata',
    };
  }
}

class SqliteProjectionSourceIdentity {
  const SqliteProjectionSourceIdentity({
    required this.sourceId,
    required this.label,
    required this.surfaceRole,
    required this.truthId,
    required this.truthLabel,
    required this.isReadOnlyProjection,
    this.storageStrategyId = '',
  });

  final String sourceId;
  final String label;
  final String surfaceRole;
  final String truthId;
  final String truthLabel;
  final bool isReadOnlyProjection;
  final String storageStrategyId;

  Map<String, Object?> toJson() {
    // 中文注释: 这个对象会被投影/探针/日志跨层传递，因此需要稳定 JSON 形态。
    return <String, Object?>{
      'source_id': sourceId,
      'label': label,
      'surface_role': surfaceRole,
      'truth_id': truthId,
      'truth_label': truthLabel,
      'is_read_only_projection': isReadOnlyProjection,
      'storage_strategy_id': storageStrategyId,
    };
  }

  factory SqliteProjectionSourceIdentity.fromJson(Map<String, Object?> json) {
    // 中文注释: 反序列化只接受稳定字段，避免新老投影口径在跨层流转时丢真相源身份。
    return SqliteProjectionSourceIdentity(
      sourceId: json['source_id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      surfaceRole: json['surface_role']?.toString() ?? '',
      truthId: json['truth_id']?.toString() ?? '',
      truthLabel: json['truth_label']?.toString() ?? '',
      isReadOnlyProjection: json['is_read_only_projection'] == true,
      storageStrategyId: json['storage_strategy_id']?.toString() ?? '',
    );
  }

  SqliteProjectionSourceIdentity copyWith({
    String? sourceId,
    String? label,
    String? surfaceRole,
    String? truthId,
    String? truthLabel,
    bool? isReadOnlyProjection,
    String? storageStrategyId,
  }) {
    // 中文注释: 这是纯值对象，copyWith 只用于投影组合和测试构造。
    return SqliteProjectionSourceIdentity(
      sourceId: sourceId ?? this.sourceId,
      label: label ?? this.label,
      surfaceRole: surfaceRole ?? this.surfaceRole,
      truthId: truthId ?? this.truthId,
      truthLabel: truthLabel ?? this.truthLabel,
      isReadOnlyProjection: isReadOnlyProjection ?? this.isReadOnlyProjection,
      storageStrategyId: storageStrategyId ?? this.storageStrategyId,
    );
  }
}

class SqliteProjectionNode {
  const SqliteProjectionNode({
    required this.nodeId,
    required this.title,
    required this.kind,
    required this.groupKind,
    required this.summary,
    required this.relativePath,
    required this.sourceIdentity,
    required this.depth,
    required this.sortOrder,
    required this.isReadOnlyProjection,
    required this.isDiagnosticLayer,
    this.childNodeIds = const <String>[],
  });

  final String nodeId;
  final String title;
  final SqliteProjectionNodeKind kind;
  final SqliteProjectionGroupKind groupKind;
  final String summary;
  final String relativePath;
  final SqliteProjectionSourceIdentity sourceIdentity;
  final int depth;
  final int sortOrder;
  final bool isReadOnlyProjection;
  final bool isDiagnosticLayer;
  final List<String> childNodeIds;

  bool get hasChildren => childNodeIds.isNotEmpty;

  Map<String, Object?> toJson() {
    // 中文注释: 节点 JSON 只保留稳定展示与回跳字段，避免把临时 UI 状态一起塞进投影合同。
    return <String, Object?>{
      'node_id': nodeId,
      'title': title,
      'kind': kind.label,
      'group_kind': groupKind.name,
      'summary': summary,
      'relative_path': relativePath,
      'source_identity': sourceIdentity.toJson(),
      'depth': depth,
      'sort_order': sortOrder,
      'is_read_only_projection': isReadOnlyProjection,
      'is_diagnostic_layer': isDiagnosticLayer,
      'child_node_ids': List<String>.unmodifiable(childNodeIds),
    };
  }

  factory SqliteProjectionNode.fromJson(Map<String, Object?> json) {
    // 中文注释: 反序列化只依赖稳定字段，方便 future adapter 直接从缓存或测试数据恢复节点合同。
    return SqliteProjectionNode(
      nodeId: json['node_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      kind: SqliteVisibilityPolicy._nodeKindFromJsonValue(json['kind']),
      groupKind: SqliteVisibilityPolicy._groupKindFromJsonValue(
        json['group_kind'],
      ),
      summary: json['summary']?.toString() ?? '',
      relativePath: json['relative_path']?.toString() ?? '',
      sourceIdentity: SqliteProjectionSourceIdentity.fromJson(
        SqliteVisibilityPolicy._mapValue(json['source_identity']),
      ),
      depth: SqliteVisibilityPolicy._intValue(json['depth']),
      sortOrder: SqliteVisibilityPolicy._intValue(json['sort_order']),
      isReadOnlyProjection: json['is_read_only_projection'] == true,
      isDiagnosticLayer: json['is_diagnostic_layer'] == true,
      childNodeIds: SqliteVisibilityPolicy._stringList(json['child_node_ids']),
    );
  }

  SqliteProjectionNode copyWith({
    String? nodeId,
    String? title,
    SqliteProjectionNodeKind? kind,
    SqliteProjectionGroupKind? groupKind,
    String? summary,
    String? relativePath,
    SqliteProjectionSourceIdentity? sourceIdentity,
    int? depth,
    int? sortOrder,
    bool? isReadOnlyProjection,
    bool? isDiagnosticLayer,
    List<String>? childNodeIds,
  }) {
    // 中文注释: 节点 copyWith 只用于投影树二次加工，避免直接修改原始树对象。
    return SqliteProjectionNode(
      nodeId: nodeId ?? this.nodeId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      groupKind: groupKind ?? this.groupKind,
      summary: summary ?? this.summary,
      relativePath: relativePath ?? this.relativePath,
      sourceIdentity: sourceIdentity ?? this.sourceIdentity,
      depth: depth ?? this.depth,
      sortOrder: sortOrder ?? this.sortOrder,
      isReadOnlyProjection: isReadOnlyProjection ?? this.isReadOnlyProjection,
      isDiagnosticLayer: isDiagnosticLayer ?? this.isDiagnosticLayer,
      childNodeIds: childNodeIds ?? this.childNodeIds,
    );
  }
}

class SqliteVisibilityPolicy {
  const SqliteVisibilityPolicy({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  static const List<SqliteProjectionGroupKind> _mainTreeGroupOrder =
      <SqliteProjectionGroupKind>[
        SqliteProjectionGroupKind.projectOverview,
        SqliteProjectionGroupKind.bodyAndChapters,
        SqliteProjectionGroupKind.outlineAndSetting,
        SqliteProjectionGroupKind.projectMaterials,
        SqliteProjectionGroupKind.referenceMounts,
        SqliteProjectionGroupKind.importSources,
        SqliteProjectionGroupKind.extractionAndReview,
        SqliteProjectionGroupKind.exportAndProjection,
      ];

  List<SqliteProjectionGroupKind> defaultMainTreeGroups() {
    // 中文注释: 这份顺序就是 SQLite 主语义树的稳定主分区，不允许 UI 侧随意重排。
    return List<SqliteProjectionGroupKind>.unmodifiable(_mainTreeGroupOrder);
  }

  List<SqliteProjectionNode> defaultMainTreeGroupNodes({
    required ProjectStorageStrategy storageStrategy,
  }) {
    // 中文注释: 组节点只表达语义树骨架，后续 adapters 只需把具体条目挂到这些固定锚点下。
    return _mainTreeGroupOrder
        .map(
          (groupKind) => SqliteProjectionNode(
            nodeId: 'sqlite_group_${groupKind.name}',
            title: groupKind.label,
            kind: SqliteProjectionNodeKind.groupHeader,
            groupKind: groupKind,
            summary: groupKind.summary,
            relativePath: '',
            sourceIdentity: _groupSourceIdentity(
              storageStrategy: storageStrategy,
              groupKind: groupKind,
            ),
            depth: 0,
            sortOrder: _mainTreeGroupOrder.indexOf(groupKind),
            isReadOnlyProjection: true,
            isDiagnosticLayer: groupKind.isDiagnosticLayer,
          ),
        )
        .toList(growable: false);
  }

  bool shouldHideFromDefaultTree(
    String relativePath, {
    required ProjectStorageStrategy storageStrategy,
    bool isDirectory = false,
  }) {
    // 中文注释: 默认树只展示主语义分区，内部状态、兼容根和高噪声文件继续折叠到投影/诊断层。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return false;
    }
    if (cleanPath == 'readme.md' ||
        RegExp(r'^[^/]+/readme\.md$').hasMatch(cleanPath)) {
      return true;
    }
    if (cleanPath.endsWith('.json') || cleanPath.endsWith('.jsonl')) {
      return true;
    }
    if (_isDiagnosticLayerPath(cleanPath)) {
      return true;
    }
    if (_isLegacyCompatibilityPath(cleanPath)) {
      return true;
    }
    if (ProjectWorkspaceCatalog.isAdvancedWorkspacePath(cleanPath) ||
        ProjectWorkspaceCatalog.isInternalWorkspacePath(cleanPath)) {
      return true;
    }
    if (storageStrategy == ProjectStorageStrategy.sqliteProjectStore &&
        _isSemanticProjectionPath(cleanPath)) {
      return true;
    }
    return isDirectory && cleanPath.startsWith('.novel_agent/');
  }

  bool isDiagnosticLayerPath(String relativePath) {
    // 中文注释: 诊断层路径单独暴露给 app 后续高级面判断，避免和主语义树混淆。
    return _isDiagnosticLayerPath(_normalizePath(relativePath));
  }

  SqliteProjectionGroupKind groupForPath(
    String relativePath, {
    required ProjectStorageStrategy storageStrategy,
    bool isDirectory = false,
  }) {
    // 中文注释: 这里把物理路径归入稳定语义分区，后续 adapters 只需依赖这个合同做树投影。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return SqliteProjectionGroupKind.projectOverview;
    }
    if (_isDiagnosticLayerPath(cleanPath)) {
      return SqliteProjectionGroupKind.diagnosticReadOnly;
    }
    final root = cleanPath.split('/').first;
    final second = cleanPath.contains('/')
        ? cleanPath.substring(root.length + 1).split('/').first
        : '';
    switch (root) {
      case 'premise':
      case 'specs':
        return SqliteProjectionGroupKind.projectOverview;
      case 'chapters':
      case 'scenes':
        return SqliteProjectionGroupKind.bodyAndChapters;
      case 'outlines':
        return SqliteProjectionGroupKind.outlineAndSetting;
      case 'assets':
        switch (second) {
          case 'world':
          case 'styles':
          case 'characters':
          case 'organizations':
          case 'items':
          case 'relationships':
          case 'timeline':
          case 'foreshadows':
            return SqliteProjectionGroupKind.outlineAndSetting;
          default:
            return SqliteProjectionGroupKind.projectMaterials;
        }
      case 'knowledge':
      case 'research':
      case 'summaries':
      case 'tasks':
      case 'analysis':
      case 'inspiration':
      case 'constraints':
      case 'continuity':
      case 'reviews':
        return SqliteProjectionGroupKind.projectMaterials;
      case 'references':
      case 'reference':
      case 'reference_works':
      case 'project_references':
        return SqliteProjectionGroupKind.referenceMounts;
      case 'imports':
      case 'inbox':
      case 'source_documents':
      case 'sources':
      case 'source':
        return SqliteProjectionGroupKind.importSources;
      case 'tracking':
      case 'extraction':
        return SqliteProjectionGroupKind.extractionAndReview;
      case 'exports':
      case 'projection':
      case 'projections':
        return SqliteProjectionGroupKind.exportAndProjection;
      default:
        if (cleanPath.startsWith('.novel_agent/information/')) {
          return SqliteProjectionGroupKind.extractionAndReview;
        }
        return isDirectory && _isLegacyCompatibilityPath(cleanPath)
            ? SqliteProjectionGroupKind.projectMaterials
            : SqliteProjectionGroupKind.projectMaterials;
    }
  }

  SqliteProjectionNodeKind nodeKindForPath(
    String relativePath, {
    required ProjectStorageStrategy storageStrategy,
    bool isDirectory = false,
  }) {
    // 中文注释: 节点类型只关心“这是目录、文档、投影还是诊断项”，不要把树分区职责混进来。
    final groupKind = groupForPath(
      relativePath,
      storageStrategy: storageStrategy,
      isDirectory: isDirectory,
    );
    if (groupKind.isDiagnosticLayer) {
      return SqliteProjectionNodeKind.diagnostic;
    }
    if (isDirectory) {
      return SqliteProjectionNodeKind.groupHeader;
    }
    if (storageStrategy == ProjectStorageStrategy.sqliteProjectStore &&
        _isMainSemanticGroup(groupKind)) {
      return SqliteProjectionNodeKind.projection;
    }
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.startsWith('.novel_agent/')) {
      return SqliteProjectionNodeKind.record;
    }
    if (groupKind == SqliteProjectionGroupKind.referenceMounts) {
      return SqliteProjectionNodeKind.attachment;
    }
    if (groupKind == SqliteProjectionGroupKind.importSources) {
      return SqliteProjectionNodeKind.source;
    }
    if (groupKind == SqliteProjectionGroupKind.extractionAndReview) {
      return SqliteProjectionNodeKind.record;
    }
    if (groupKind == SqliteProjectionGroupKind.exportAndProjection) {
      return SqliteProjectionNodeKind.projection;
    }
    if (_isSemanticProjectionPath(cleanPath)) {
      return SqliteProjectionNodeKind.projection;
    }
    return SqliteProjectionNodeKind.document;
  }

  bool _isMainSemanticGroup(SqliteProjectionGroupKind groupKind) {
    // 中文注释: 主语义树的四个内容分区都视为 SQLite 投影节点，和挂载/导入/审核/导出层分开。
    return groupKind == SqliteProjectionGroupKind.projectOverview ||
        groupKind == SqliteProjectionGroupKind.bodyAndChapters ||
        groupKind == SqliteProjectionGroupKind.outlineAndSetting ||
        groupKind == SqliteProjectionGroupKind.projectMaterials;
  }

  SqliteProjectionSourceIdentity sourceIdentityForPath(
    String relativePath, {
    required ProjectStorageStrategy storageStrategy,
    bool isDirectory = false,
  }) {
    // 中文注释: 来源身份把“真相源是谁”和“当前节点为什么只读”拆开，避免 UI 自己猜测来源。
    final cleanPath = _normalizePath(relativePath);
    final groupKind = groupForPath(
      cleanPath,
      storageStrategy: storageStrategy,
      isDirectory: isDirectory,
    );
    final sourceId =
        '${storageStrategy.id}:${cleanPath.isEmpty ? 'root' : cleanPath}';
    switch (groupKind) {
      case SqliteProjectionGroupKind.projectOverview:
      case SqliteProjectionGroupKind.bodyAndChapters:
      case SqliteProjectionGroupKind.outlineAndSetting:
      case SqliteProjectionGroupKind.projectMaterials:
        return SqliteProjectionSourceIdentity(
          sourceId: sourceId,
          label: storageStrategy == ProjectStorageStrategy.sqliteProjectStore
              ? 'SQLite 主事实源'
              : '文件主事实源',
          surfaceRole:
              storageStrategy == ProjectStorageStrategy.sqliteProjectStore
              ? 'sqlite_projection'
              : 'filesystem_primary_fact_source',
          truthId: storageStrategy.id,
          truthLabel:
              storageStrategy == ProjectStorageStrategy.sqliteProjectStore
              ? 'sqlite_project_store'
              : 'markdown_project_store',
          isReadOnlyProjection:
              storageStrategy == ProjectStorageStrategy.sqliteProjectStore,
          storageStrategyId: storageStrategy.id,
        );
      case SqliteProjectionGroupKind.referenceMounts:
        return SqliteProjectionSourceIdentity(
          sourceId: sourceId,
          label: '参考资产挂载',
          surfaceRole: 'reference_mount_projection',
          truthId: 'reference_evidence_substrate',
          truthLabel: '参考资产库',
          isReadOnlyProjection: true,
          storageStrategyId: storageStrategy.id,
        );
      case SqliteProjectionGroupKind.importSources:
        return SqliteProjectionSourceIdentity(
          sourceId: sourceId,
          label: '导入源',
          surfaceRole: 'import_source_projection',
          truthId: 'import_source',
          truthLabel: '原始导入素材',
          isReadOnlyProjection: true,
          storageStrategyId: storageStrategy.id,
        );
      case SqliteProjectionGroupKind.extractionAndReview:
        return SqliteProjectionSourceIdentity(
          sourceId: sourceId,
          label: '提取与审核',
          surfaceRole: 'review_projection',
          truthId: 'extraction_review_pipeline',
          truthLabel: '提取与审核流程',
          isReadOnlyProjection: true,
          storageStrategyId: storageStrategy.id,
        );
      case SqliteProjectionGroupKind.exportAndProjection:
        return SqliteProjectionSourceIdentity(
          sourceId: sourceId,
          label: '导出与投影',
          surfaceRole: 'export_projection',
          truthId: 'projection_export',
          truthLabel: '导出/投影产物',
          isReadOnlyProjection: true,
          storageStrategyId: storageStrategy.id,
        );
      case SqliteProjectionGroupKind.diagnosticReadOnly:
        return SqliteProjectionSourceIdentity(
          sourceId: sourceId,
          label: '高级只读诊断',
          surfaceRole: 'diagnostic_read_only',
          truthId: 'diagnostic_layer',
          truthLabel: '内部诊断层',
          isReadOnlyProjection: true,
          storageStrategyId: storageStrategy.id,
        );
    }
  }

  SqliteProjectionNode buildNode({
    required String relativePath,
    required ProjectStorageStrategy storageStrategy,
    String title = '',
    String summary = '',
    bool isDirectory = false,
    int depth = 0,
    int sortOrder = 0,
    List<String> childNodeIds = const <String>[],
  }) {
    // 中文注释: 这里把路径、分组、来源身份统一折叠成一个可消费节点，后续 adapter 只需补树遍历即可。
    final cleanPath = _normalizePath(relativePath);
    final groupKind = groupForPath(
      cleanPath,
      storageStrategy: storageStrategy,
      isDirectory: isDirectory,
    );
    final nodeKind = nodeKindForPath(
      cleanPath,
      storageStrategy: storageStrategy,
      isDirectory: isDirectory,
    );
    final resolvedTitle = title.trim().isNotEmpty
        ? title.trim()
        : _titleForPath(cleanPath, isDirectory: isDirectory);
    return SqliteProjectionNode(
      nodeId: cleanPath.isEmpty ? 'sqlite_root' : cleanPath,
      title: resolvedTitle,
      kind: nodeKind,
      groupKind: groupKind,
      summary: summary.trim().isEmpty ? groupKind.summary : summary.trim(),
      relativePath: cleanPath,
      sourceIdentity: sourceIdentityForPath(
        cleanPath,
        storageStrategy: storageStrategy,
        isDirectory: isDirectory,
      ),
      depth: depth,
      sortOrder: sortOrder,
      isReadOnlyProjection:
          storageStrategy == ProjectStorageStrategy.sqliteProjectStore ||
          groupKind.isDiagnosticLayer,
      isDiagnosticLayer: groupKind.isDiagnosticLayer,
      childNodeIds: childNodeIds,
    );
  }

  bool _isDiagnosticLayerPath(String relativePath) {
    // 中文注释: 诊断层优先拦截 .novel_agent、sessions、backups 和数据库文件，避免它们进入主语义树。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return false;
    }
    if (cleanPath.endsWith('.db') || cleanPath.endsWith('.sqlite')) {
      return true;
    }
    return ProjectWorkspaceCatalog.isInternalWorkspacePath(cleanPath) ||
        cleanPath.startsWith('sessions/') ||
        cleanPath.startsWith('backups/');
  }

  bool _isLegacyCompatibilityPath(String relativePath) {
    // 中文注释: 旧兼容根必须从默认树中折叠出去，但仍可以在语义投影里被重新归类。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return false;
    }
    for (final descriptor
        in ProjectWorkspaceCatalog.legacyResourceCompatibilityDirs) {
      final basePath = _normalizePath(descriptor.path);
      if (cleanPath == basePath || cleanPath.startsWith('$basePath/')) {
        return true;
      }
    }
    return false;
  }

  bool _isSemanticProjectionPath(String relativePath) {
    // 中文注释: 语义投影路径表示“物理上仍是文件，但逻辑上应作为 SQLite 项目的投影节点消费”。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return false;
    }
    if (cleanPath.startsWith('.novel_agent/information/') ||
        cleanPath.startsWith('references/') ||
        cleanPath.startsWith('imports/') ||
        cleanPath.startsWith('tracking/') ||
        cleanPath.startsWith('exports/')) {
      return true;
    }
    return _isLegacyCompatibilityPath(cleanPath);
  }

  String _titleForPath(String relativePath, {required bool isDirectory}) {
    // 中文注释: 节点标题默认取最后一级路径名，目录则尽量保留可读中文目录名映射。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return 'SQLite 项目';
    }
    if (isDirectory) {
      for (final descriptor
          in ProjectWorkspaceCatalog.resourceTreeDirectoryDescriptors) {
        final descriptorPath = _normalizePath(descriptor.path);
        if (descriptorPath == cleanPath) {
          return descriptor.name;
        }
      }
    }
    final segments = cleanPath.split('/');
    return segments.isEmpty ? cleanPath : segments.last;
  }

  SqliteProjectionSourceIdentity _groupSourceIdentity({
    required ProjectStorageStrategy storageStrategy,
    required SqliteProjectionGroupKind groupKind,
  }) {
    // 中文注释: 组节点也需要来源身份，这样 UI 可以区分“这是树分区”还是“这是实际内容节点”。
    return SqliteProjectionSourceIdentity(
      sourceId: 'sqlite_group:${groupKind.name}',
      label: groupKind.label,
      surfaceRole: 'group_header',
      truthId: storageStrategy.id,
      truthLabel: storageStrategy.id,
      isReadOnlyProjection: true,
      storageStrategyId: storageStrategy.id,
    );
  }

  String _normalizePath(String relativePath) {
    // 中文注释: 路径归一化统一把反斜杠和尾部斜杠清掉，避免同一条语义路径在投影合同里出现多份。
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
  }

  static SqliteProjectionNodeKind _nodeKindFromJsonValue(Object? value) {
    // 中文注释: 节点类型反序列化只接受稳定字符串值，避免大写/枚举对象直接穿透。
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    for (final kind in SqliteProjectionNodeKind.values) {
      if (kind.label == normalized) {
        return kind;
      }
    }
    return SqliteProjectionNodeKind.document;
  }

  static SqliteProjectionGroupKind _groupKindFromJsonValue(Object? value) {
    // 中文注释: 分组反序列化接受枚举名字符串，便于测试和缓存直接 round-trip。
    final normalized = value?.toString().trim() ?? '';
    for (final kind in SqliteProjectionGroupKind.values) {
      if (kind.name == normalized) {
        return kind;
      }
    }
    return SqliteProjectionGroupKind.projectOverview;
  }

  static Map<String, Object?> _mapValue(Object? value) {
    // 中文注释: 这里只做最小 map 归一化，避免 fromJson 依赖外层额外的 value reader。
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return const <String, Object?>{};
  }

  static int _intValue(Object? value) {
    // 中文注释: 数字字段从 JSON 恢复时只接受最小兼容转换，不在这里引入额外的字符串解析策略。
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(Object? value) {
    // 中文注释: child node ids 只接受字符串列表，其他内容一律忽略，避免投影树结构被脏数据污染。
    if (value is List<String>) {
      return List<String>.unmodifiable(value);
    }
    if (value is List) {
      return List<String>.unmodifiable(
        value
            .map((entry) => entry.toString())
            .where((item) => item.trim().isNotEmpty),
      );
    }
    return const <String>[];
  }
}
