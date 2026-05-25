import 'inspiration_convergence_stage.dart';
import 'inspiration_field_key.dart';

class InspirationConvergenceStageCatalogService {
  const InspirationConvergenceStageCatalogService();

  static const String seedStageId = 'seed';
  static const String premiseStageId = 'premise';
  static const String worldStageId = 'world';
  static const String characterStageId = 'characters';
  static const String styleStageId = 'style';
  static const String autonomyStageId = 'autonomy';
  static const String readyStageId = 'ready';

  List<InspirationConvergenceStage> stages() {
    return const <InspirationConvergenceStage>[
      InspirationConvergenceStage(
        id: seedStageId,
        title: '灵感种子',
        description: '先确认当前材料来自一句想法、已有片段还是已有设定。',
        order: 10,
        fieldKeys: <String>[InspirationFieldKey.seedMaterial],
      ),
      InspirationConvergenceStage(
        id: premiseStageId,
        title: '故事前提',
        description: '把灵感收束成承诺、主线、结局范围和长篇前提。',
        order: 20,
        fieldKeys: <String>[
          InspirationFieldKey.premise,
          InspirationFieldKey.corePromise,
          InspirationFieldKey.mainArc,
          InspirationFieldKey.volumeMap,
          InspirationFieldKey.endingCommitment,
        ],
      ),
      InspirationConvergenceStage(
        id: worldStageId,
        title: '世界规则',
        description: '把世界锚点和不可违背的规则沉淀为稳定约束。',
        order: 30,
        fieldKeys: <String>[InspirationFieldKey.worldAnchor],
      ),
      InspirationConvergenceStage(
        id: characterStageId,
        title: '角色骨架',
        description: '把主角驱动力和核心角色焦点收束成可复用人物入口。',
        order: 40,
        fieldKeys: <String>[
          InspirationFieldKey.protagonistDrive,
          InspirationFieldKey.coreCharacters,
        ],
      ),
      InspirationConvergenceStage(
        id: styleStageId,
        title: '风格定锚',
        description: '确认风格目标、语言边界和不希望智能体偏离的味道。',
        order: 50,
        fieldKeys: <String>[
          InspirationFieldKey.styleTarget,
          InspirationFieldKey.styleBoundaries,
        ],
      ),
      InspirationConvergenceStage(
        id: autonomyStageId,
        title: '托管边界',
        description: '定义哪些事情可自动推进，哪些改动必须先回到确认。',
        order: 60,
        fieldKeys: <String>[InspirationFieldKey.autonomyGuardrails],
      ),
      InspirationConvergenceStage(
        id: readyStageId,
        title: '启动确认',
        description: '确认当前灵感已具备进入规划、项目初始化或长任务的条件。',
        order: 70,
        fieldKeys: <String>[InspirationFieldKey.readySignal],
      ),
    ];
  }

  InspirationConvergenceStage? stageById(String stageId) {
    final cleanStageId = stageId.trim();
    for (final stage in stages()) {
      if (stage.id == cleanStageId) {
        return stage;
      }
    }
    return null;
  }

  InspirationConvergenceStage? stageForFieldKey(String fieldKey) {
    final cleanFieldKey = fieldKey.trim();
    if (cleanFieldKey.isEmpty) {
      return null;
    }
    for (final stage in stages()) {
      if (stage.fieldKeys.contains(cleanFieldKey)) {
        return stage;
      }
    }
    return null;
  }

  String stageIdForFieldKey(String fieldKey) {
    return stageForFieldKey(fieldKey)?.id ?? '';
  }
}
