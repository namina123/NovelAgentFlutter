import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_sqlite_path_service.dart';

class SqliteProjectSemanticProjectionBuilderService {
  const SqliteProjectSemanticProjectionBuilderService({
    SqliteVisibilityPolicy? visibilityPolicy,
  }) : _visibilityPolicy = visibilityPolicy ?? const SqliteVisibilityPolicy(),
       _sqliteDatabaseRelativePath =
           ProjectSqlitePathService.databaseRelativePath;

  final SqliteVisibilityPolicy _visibilityPolicy;
  final String _sqliteDatabaseRelativePath;

  SqliteProjectSemanticProjection build({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
    required List<JsonMap> workspaceEntries,
  }) {
    // 中文注释: 这里把 SQLite 项目的可见目录、已存在条目和稳定分区一起折叠成“语义树 + 投影文档”双份合同，供后续宿主直接消费。
    final visibleEntries = _visibleWorkspaceEntries(
      manifest: manifest,
      workspaceEntries: workspaceEntries,
    );
    final entryNodes = _buildEntryNodes(
      manifest: manifest,
      layout: layout,
      visibleEntries: visibleEntries,
    );
    final groupNodes = _buildGroupNodes(
      manifest: manifest,
      entryNodes: entryNodes,
    );
    final rootNode = _buildRootNode(
      manifest: manifest,
      groupNodes: groupNodes,
      entryNodes: entryNodes,
    );
    final documents = _buildDocuments(
      rootPath: rootPath,
      manifest: manifest,
      groupNodes: groupNodes,
      entryNodes: entryNodes,
    );
    return SqliteProjectSemanticProjection(
      rootNode: rootNode,
      groupNodes: groupNodes,
      entryNodes: entryNodes,
      documents: documents,
    );
  }

  List<_SqliteProjectionEntry> _visibleWorkspaceEntries({
    required ProjectManifest manifest,
    required List<JsonMap> workspaceEntries,
  }) {
    // 中文注释: 默认树只消费主语义内容与已存在的可读入口，投影自身和内部数据库文件都要先折叠掉。
    final entries = <_SqliteProjectionEntry>[];
    for (final entry in workspaceEntries) {
      final relativePath = ValueReaders.stringValue(
        entry['relative_path'],
      ).replaceAll('\\', '/').trim();
      if (relativePath.isEmpty) {
        continue;
      }
      if (_isProjectionSurfacePath(relativePath)) {
        continue;
      }
      final isDirectory = ValueReaders.boolValue(entry['is_dir']);
      if (_visibilityPolicy.shouldHideFromDefaultTree(
        relativePath,
        storageStrategy: manifest.storageStrategy,
        isDirectory: isDirectory,
      )) {
        continue;
      }
      entries.add(
        _SqliteProjectionEntry(
          relativePath: relativePath,
          title: ValueReaders.stringValue(entry['display_name']).trim(),
          summary: _summaryForPath(
            relativePath: relativePath,
            isDirectory: isDirectory,
            storageStrategy: manifest.storageStrategy,
          ),
          isDirectory: isDirectory,
          sourceIdentity: _visibilityPolicy.sourceIdentityForPath(
            relativePath,
            storageStrategy: manifest.storageStrategy,
            isDirectory: isDirectory,
          ),
        ),
      );
    }
    entries.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    return entries;
  }

  List<SqliteProjectionNode> _buildEntryNodes({
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
    required List<_SqliteProjectionEntry> visibleEntries,
  }) {
    // 中文注释: 目录与文件都折叠成可读节点，但仍保留原始相对路径和来源身份，方便 app 后续直接投影。
    final descriptorsByPath = <String, WorkspaceDirectoryDescriptor>{
      for (final descriptor in layout.readableProjectionDirectories)
        _normalizePath(descriptor.path): descriptor,
      for (final descriptor in layout.primaryContentDirectories)
        _normalizePath(descriptor.path): descriptor,
    };
    final nodes = <SqliteProjectionNode>[];
    var sortOrder = 0;
    for (final entry in visibleEntries) {
      final descriptor = descriptorsByPath[_normalizePath(entry.relativePath)];
      final node = _visibilityPolicy
          .buildNode(
            relativePath: entry.relativePath,
            storageStrategy: manifest.storageStrategy,
            title: entry.title.isNotEmpty
                ? entry.title
                : descriptor?.name ?? _fallbackTitleOf(entry.relativePath),
            summary: descriptor?.purpose.trim().isNotEmpty == true
                ? descriptor!.purpose.trim()
                : entry.summary,
            isDirectory: entry.isDirectory,
            depth: _depthOf(entry.relativePath),
            sortOrder: sortOrder++,
          )
          .copyWith(sourceIdentity: entry.sourceIdentity);
      nodes.add(node);
    }
    return nodes;
  }

  List<SqliteProjectionNode> _buildGroupNodes({
    required ProjectManifest manifest,
    required List<SqliteProjectionNode> entryNodes,
  }) {
    // 中文注释: 组节点是 SQLite 主语义树的骨架，子节点只挂真实可读条目，不挂投影自身。
    final nodesByGroup = <SqliteProjectionGroupKind, List<String>>{};
    for (final entryNode in entryNodes) {
      nodesByGroup
          .putIfAbsent(entryNode.groupKind, () => <String>[])
          .add(entryNode.nodeId);
    }
    final groupNodes = _visibilityPolicy.defaultMainTreeGroupNodes(
      storageStrategy: manifest.storageStrategy,
    );
    return groupNodes
        .map((groupNode) {
          return groupNode.copyWith(
            childNodeIds:
                nodesByGroup[groupNode.groupKind]?.toList(growable: false) ??
                const <String>[],
          );
        })
        .toList(growable: false);
  }

  SqliteProjectionNode _buildRootNode({
    required ProjectManifest manifest,
    required List<SqliteProjectionNode> groupNodes,
    required List<SqliteProjectionNode> entryNodes,
  }) {
    // 中文注释: 根节点只做语义树总入口，不承载任何可编辑事实，避免后续 app 把它当作普通文档。
    return SqliteProjectionNode(
      nodeId: 'sqlite_root',
      title: manifest.title.trim().isEmpty
          ? 'SQLite 项目'
          : manifest.title.trim(),
      kind: SqliteProjectionNodeKind.root,
      groupKind: SqliteProjectionGroupKind.projectOverview,
      summary: 'SQLite 主事实源的可读语义树与投影入口。',
      relativePath: '',
      sourceIdentity: SqliteProjectionSourceIdentity(
        sourceId: 'sqlite_project_root:${manifest.title}',
        label: 'SQLite 项目语义树',
        surfaceRole: 'sqlite_project_semantic_root',
        truthId: manifest.storageStrategy.id,
        truthLabel: manifest.storageStrategy.id,
        isReadOnlyProjection: true,
        storageStrategyId: manifest.storageStrategy.id,
      ),
      depth: 0,
      sortOrder: 0,
      isReadOnlyProjection: true,
      isDiagnosticLayer: false,
      childNodeIds: groupNodes
          .map((node) => node.nodeId)
          .toList(growable: false),
    );
  }

  List<SqliteProjectSemanticProjectionDocument> _buildDocuments({
    required String rootPath,
    required ProjectManifest manifest,
    required List<SqliteProjectionNode> groupNodes,
    required List<SqliteProjectionNode> entryNodes,
  }) {
    // 中文注释: 文档层输出给宿主读取，不直接依赖数据库浏览器；它只是语义树的可读投影，不是另一个事实源。
    final indexDocument = SqliteProjectSemanticProjectionDocument(
      relativePath: 'premise/sqlite_projection/index.md',
      title: 'SQLite 项目语义树',
      markdown: _buildIndexMarkdown(
        rootPath: rootPath,
        manifest: manifest,
        groupNodes: groupNodes,
        entryNodes: entryNodes,
      ),
      sourceIdentity: _visibilityPolicy.sourceIdentityForPath(
        'premise/sqlite_projection/index.md',
        storageStrategy: manifest.storageStrategy,
      ),
      nodeIds: groupNodes.map((node) => node.nodeId).toList(growable: false),
    );
    final groupDocuments = groupNodes
        .map((groupNode) {
          final groupEntryNodes =
              entryNodes
                  .where((entry) => entry.groupKind == groupNode.groupKind)
                  .toList(growable: false)
                ..sort(
                  (left, right) => left.sortOrder.compareTo(right.sortOrder),
                );
          return SqliteProjectSemanticProjectionDocument(
            relativePath:
                'premise/sqlite_projection/${_snakeCase(groupNode.groupKind.name)}.md',
            title: groupNode.groupKind.label,
            markdown: _buildGroupMarkdown(
              rootPath: rootPath,
              manifest: manifest,
              groupNode: groupNode,
              entryNodes: groupEntryNodes,
            ),
            sourceIdentity: groupNode.sourceIdentity,
            nodeIds: <String>[
              groupNode.nodeId,
              ...groupEntryNodes.map((node) => node.nodeId),
            ],
          );
        })
        .toList(growable: false);
    return <SqliteProjectSemanticProjectionDocument>[
      indexDocument,
      ...groupDocuments,
    ];
  }

  String _buildIndexMarkdown({
    required String rootPath,
    required ProjectManifest manifest,
    required List<SqliteProjectionNode> groupNodes,
    required List<SqliteProjectionNode> entryNodes,
  }) {
    // 中文注释: 根索引只讲“语义树在哪里、分了哪几层、每层有哪些可读入口”，不把实现细节摊成数据库清单。
    final lines = <String>[
      _frontmatter(
        projectionId: 'sqlite_project_semantic_tree_index',
        title: 'SQLite 项目语义树',
        sourceOfTruthPaths: <String>[
          ProjectManifestCodecService.manifestRelativePath,
          _sqliteDatabaseRelativePath,
        ],
      ),
      '# SQLite 项目语义树',
      '',
      '> 这是 SQLite 主事实源的可读摘要，不是数据库浏览器，也不是 `.db` 文件浏览视图。',
      '> 默认语义树只展示可理解的项目内容域，内部数据库文件与隐藏状态折叠到实现层。',
      '',
      '## 快速入口',
      '',
      '- `${ProjectSupportDocumentCatalog.projectOverviewRelativePath}`：项目总览与快速说明。',
      '- `premise/sqlite_projection/`：SQLite 语义树投影目录。',
      '',
      '## 主语义分区',
      '',
      ...groupNodes
          .map((groupNode) {
            final groupEntryCount = entryNodes
                .where((entry) => entry.groupKind == groupNode.groupKind)
                .length;
            return <String>[
              '### ${groupNode.groupKind.label}',
              '',
              '- 摘要：${groupNode.groupKind.summary}',
              '- 节点数：${groupEntryCount}',
              '- 来源类型：${_formatSourceIdentity(groupNode.sourceIdentity)}',
              '- 来源：${groupNode.sourceIdentity.truthLabel}',
              '- 只读：${groupNode.isReadOnlyProjection ? '是' : '否'}',
              '',
            ];
          })
          .expand((segment) => segment),
      '## 说明',
      '',
      '- `project_overview.md` 只是快速入口，不是正式故事前提，也不是唯一可读入口。',
      '- `premise/sqlite_projection/*.md` 是按语义分区生成的只读摘要。',
      '- 高级只读诊断层保留在投影合同里，但不默认展开为主语义树文件。',
      '',
    ];
    return lines.join('\n').trimRight() + '\n';
  }

  String _buildGroupMarkdown({
    required String rootPath,
    required ProjectManifest manifest,
    required SqliteProjectionNode groupNode,
    required List<SqliteProjectionNode> entryNodes,
  }) {
    // 中文注释: 分组投影直接列出该分区下的真实条目，便于 app/CLI 以后按组消费而不是按原始目录树猜语义。
    final lines = <String>[
      _frontmatter(
        projectionId:
            'sqlite_project_semantic_tree_${groupNode.groupKind.name}',
        title: groupNode.groupKind.label,
        sourceOfTruthPaths: <String>[
          ProjectManifestCodecService.manifestRelativePath,
          _sqliteDatabaseRelativePath,
        ],
      ),
      '# ${groupNode.groupKind.label}',
      '',
      '> ${groupNode.groupKind.summary}',
      '> 这一页只展示该分区的可读摘要节点，不展示内部数据库文件。',
      '',
      '## 分区信息',
      '',
      '- 分区标签：${groupNode.groupKind.label}',
      '- 分区摘要：${groupNode.groupKind.summary}',
      '- 来源类型：${_formatSourceIdentity(groupNode.sourceIdentity)}',
      '- 来源：${groupNode.sourceIdentity.truthLabel}',
      '- 只读：${groupNode.isReadOnlyProjection ? '是' : '否'}',
      '',
      '## 节点清单',
      '',
    ];
    if (entryNodes.isEmpty) {
      lines.add('- 暂无具体节点，仅保留语义骨架。');
    } else {
      for (final entry in entryNodes) {
        lines.addAll(<String>[
          '### ${entry.title}',
          '',
          '- 相对路径：`${entry.relativePath}`',
          '- 类型：`${entry.kind.label}`',
          '- 摘要：${entry.summary.trim().isEmpty ? '无' : entry.summary}',
          '- 来源类型：${_formatSourceIdentity(entry.sourceIdentity)}',
          '- 来源：${entry.sourceIdentity.truthLabel}',
          '- 只读：${entry.isReadOnlyProjection ? '是' : '否'}',
          '',
        ]);
      }
    }
    lines.addAll(<String>[
      '## 备注',
      '',
      '- `${ProjectSupportDocumentCatalog.projectOverviewRelativePath}` 仍保留为快速说明入口，但不再是 SQLite 项目唯一可读面。',
      '- 该分区与其它分区共享同一主事实源，只是投影语义不同。',
      '',
    ]);
    return lines.join('\n').trimRight() + '\n';
  }

  String _formatSourceIdentity(SqliteProjectionSourceIdentity identity) {
    // 中文注释: 来源身份对用户暴露时保持“来源 + 真相源 + 是否只读”的最小组合，避免把内部身份字段全摊开。
    final parts = <String>[
      identity.label.trim().isEmpty ? identity.sourceId : identity.label.trim(),
      'truth:${identity.truthLabel}',
      'role:${identity.surfaceRole}',
      if (identity.isReadOnlyProjection) 'readonly',
    ];
    return parts.join(' / ');
  }

  String _summaryForPath({
    required String relativePath,
    required bool isDirectory,
    required ProjectStorageStrategy storageStrategy,
  }) {
    // 中文注释: 路径摘要只承担“这个节点为什么存在”的说明，不把完整实现状态写进可读投影。
    final groupKind = _visibilityPolicy.groupForPath(
      relativePath,
      storageStrategy: storageStrategy,
      isDirectory: isDirectory,
    );
    if (isDirectory) {
      return groupKind.summary;
    }
    return switch (groupKind) {
      SqliteProjectionGroupKind.projectOverview => '项目说明、总览摘要或快速入口。',
      SqliteProjectionGroupKind.bodyAndChapters => '正文、章节或场景内容。',
      SqliteProjectionGroupKind.outlineAndSetting => '大纲、设定或结构化创作资产。',
      SqliteProjectionGroupKind.projectMaterials => '项目资料、知识或研究素材。',
      SqliteProjectionGroupKind.referenceMounts => '参考资产库挂载或边界投影。',
      SqliteProjectionGroupKind.importSources => '导入源或待整理素材。',
      SqliteProjectionGroupKind.extractionAndReview => '提取、审核或校验记录。',
      SqliteProjectionGroupKind.exportAndProjection => '导出或投影产物。',
      SqliteProjectionGroupKind.diagnosticReadOnly => '高级只读诊断或内部恢复信息。',
    };
  }

  bool _isProjectionSurfacePath(String relativePath) {
    // 中文注释: 投影自身写出来以后不应再次进入同一轮语义树输入，否则会把 projection 当成事实源继续膨胀。
    final cleanPath = _normalizePath(relativePath);
    return ProjectSupportDocumentCatalog.isProjectOverviewPath(cleanPath) ||
        cleanPath.startsWith('premise/sqlite_projection/');
  }

  String _fallbackTitleOf(String relativePath) {
    // 中文注释: 路径标题兜底只取最后一级，目录类标题会在 descriptor 命中时替换成更友好的中文名。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return 'SQLite 项目';
    }
    return cleanPath.split('/').last;
  }

  int _depthOf(String relativePath) {
    // 中文注释: 深度只用于投影显示，不参与真实文件系统排序规则。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return 0;
    }
    return cleanPath.split('/').length - 1;
  }

  String _normalizePath(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
  }

  String _snakeCase(String value) {
    // 中文注释: 投影文件名统一转成 snake_case，避免 enum 名称直接外泄成用户可见路径。
    return value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
  }

  String _frontmatter({
    required String projectionId,
    required String title,
    required List<String> sourceOfTruthPaths,
  }) {
    // 中文注释: frontmatter 继续保持轻量稳定，方便 CLI / GUI / probe 复用同一条只读投影合同。
    final yamlWriter = const FrontmatterYamlWriterService();
    return '---\n${yamlWriter.write(<String, Object?>{'projection_id': projectionId, 'title': title, 'projection_only': true, 'source_of_truth_paths': sourceOfTruthPaths})}\n---\n';
  }
}

class SqliteProjectSemanticProjection {
  const SqliteProjectSemanticProjection({
    required this.rootNode,
    required this.groupNodes,
    required this.entryNodes,
    required this.documents,
  });

  final SqliteProjectionNode rootNode;
  final List<SqliteProjectionNode> groupNodes;
  final List<SqliteProjectionNode> entryNodes;
  final List<SqliteProjectSemanticProjectionDocument> documents;

  List<SqliteProjectionNode> get allNodes => <SqliteProjectionNode>[
    rootNode,
    ...groupNodes,
    ...entryNodes,
  ];
}

class SqliteProjectSemanticProjectionDocument {
  const SqliteProjectSemanticProjectionDocument({
    required this.relativePath,
    required this.title,
    required this.markdown,
    required this.sourceIdentity,
    required this.nodeIds,
  });

  final String relativePath;
  final String title;
  final String markdown;
  final SqliteProjectionSourceIdentity sourceIdentity;
  final List<String> nodeIds;
}

class _SqliteProjectionEntry {
  const _SqliteProjectionEntry({
    required this.relativePath,
    required this.title,
    required this.summary,
    required this.isDirectory,
    required this.sourceIdentity,
  });

  final String relativePath;
  final String title;
  final String summary;
  final bool isDirectory;
  final SqliteProjectionSourceIdentity sourceIdentity;
}
