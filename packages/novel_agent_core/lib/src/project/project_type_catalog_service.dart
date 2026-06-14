import 'project_type_definition.dart';
import 'project_storage_strategy.dart';
import 'project_trait.dart';

class ProjectTypeCatalogService {
  const ProjectTypeCatalogService();

  static const List<ProjectTypeDefinition> _definitions =
      <ProjectTypeDefinition>[
        ProjectTypeDefinition(
          id: 'novel',
          name: '普通小说',
          description: '适合常规小说创作，先围绕开局、章节续写、大纲和设定逐步推进。',
          defaultTitle: '未命名小说',
          supportedStorageStrategies: <ProjectStorageStrategy>[
            ProjectStorageStrategy.markdownProjectStore,
            ProjectStorageStrategy.sqliteProjectStore,
          ],
          defaultTraits: <ProjectTrait>[ProjectTrait.openingGuided],
        ),
        ProjectTypeDefinition(
          id: 'long_novel',
          name: '长篇长任务',
          description: '适合长篇推进和多步骤协作，强调队列、检查点与可恢复运行。',
          defaultTitle: '未命名长篇',
          supportedStorageStrategies: <ProjectStorageStrategy>[
            ProjectStorageStrategy.markdownProjectStore,
            ProjectStorageStrategy.sqliteProjectStore,
          ],
          defaultTraits: <ProjectTrait>[
            ProjectTrait.longTask,
            ProjectTrait.openingGuided,
          ],
          requiresRuntimeBaselineSelection: true,
        ),
        ProjectTypeDefinition(
          id: 'knowledge_base',
          name: '资料知识库',
          description: '适合导入、整理和检索资料，把材料沉淀成可复用知识库。',
          defaultTitle: '未命名知识库',
          supportedStorageStrategies: <ProjectStorageStrategy>[
            ProjectStorageStrategy.sqliteProjectStore,
          ],
        ),
        ProjectTypeDefinition(
          id: 'short_collection',
          name: '短篇/文集',
          description: '适合短篇合集、专题短文和统一整理。',
          defaultTitle: '未命名短文集',
          enabled: false,
        ),
        ProjectTypeDefinition(
          id: 'book_deconstruction',
          name: '拆书承接',
          description: '适合导入外部作品，抽取结构、角色和连续性信息，再衔接后续续写。',
          defaultTitle: '未命名拆书项目',
          supportedStorageStrategies: <ProjectStorageStrategy>[
            ProjectStorageStrategy.markdownProjectStore,
            ProjectStorageStrategy.sqliteProjectStore,
          ],
          defaultTraits: <ProjectTrait>[ProjectTrait.bookDeconstruction],
        ),
      ];

  List<ProjectTypeDefinition> definitions() {
    // 中文注释: 项目类型目录统一从这里暴露，避免 GUI、CLI 和项目仓储各维护一份枚举。
    return List<ProjectTypeDefinition>.unmodifiable(_definitions);
  }

  List<ProjectTypeDefinition> enabledDefinitions() {
    // 中文注释: 创建项目时通常只展示启用项，因此单独给出过滤后的稳定列表。
    return definitions().where((item) => item.enabled).toList(growable: false);
  }

  bool contains(String projectType) {
    // 中文注释: 转换和校验场景需要先判断项目类型是否真实登记，不能把未知值直接 normalize 成默认项。
    final cleanType = projectType.trim();
    for (final definition in _definitions) {
      if (definition.id == cleanType) {
        return true;
      }
    }
    return false;
  }

  String normalize(String projectType) {
    // 中文注释: 项目类型归一化只接受已登记类型，未知值统一回退到普通小说。
    final cleanType = projectType.trim();
    for (final definition in _definitions) {
      if (definition.id == cleanType) {
        return cleanType;
      }
    }
    return 'novel';
  }

  ProjectTypeDefinition definitionOf(String projectType) {
    // 中文注释: 单个类型的展示文案和默认标题都统一通过定义表读取，避免散落字符串常量。
    final normalizedType = normalize(projectType);
    for (final definition in _definitions) {
      if (definition.id == normalizedType) {
        return definition;
      }
    }
    return _definitions.first;
  }

  String defaultTitle(String projectType) {
    // 中文注释: 默认项目标题跟随项目类型，创建表单和核心用例都复用同一规则。
    return definitionOf(projectType).defaultTitle;
  }
}
