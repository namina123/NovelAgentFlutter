import 'review_type_constants.dart';

class ReviewTypeCatalogService {
  List<Map<String, Object?>> reviewTypeDefs() {
    // 中文注释: 审稿类型定义是设置页、任务中心和提示变量共享的同一套枚举来源。
    return const <Map<String, Object?>>[
      <String, Object?>{
        'id': ReviewTypeConstants.continuity,
        'name': '连续性检查',
        'description': '检查角色状态、时间线、世界规则、伏笔和前后矛盾。',
      },
      <String, Object?>{
        'id': ReviewTypeConstants.style,
        'name': '文风审稿',
        'description': '检查口吻、节奏、段落、对白和 AI 腔。',
      },
      <String, Object?>{
        'id': ReviewTypeConstants.plot,
        'name': '剧情检查',
        'description': '检查章节功能、冲突、悬念、爽点和因果链。',
      },
      <String, Object?>{
        'id': ReviewTypeConstants.general,
        'name': '综合检查',
        'description': '用于尚未细分的普通审稿报告。',
      },
    ];
  }

  String normalizeReviewType(String reviewType) {
    // 中文注释: 未知审稿类型统一回到 general，避免目录和任务模式扩散出野值。
    if (const <String>{
      ReviewTypeConstants.continuity,
      ReviewTypeConstants.style,
      ReviewTypeConstants.plot,
      ReviewTypeConstants.general,
    }.contains(reviewType.trim())) {
      return reviewType.trim();
    }
    return ReviewTypeConstants.general;
  }

  String reviewTypeLabel(String reviewType) {
    // 中文注释: 中文显示名集中在这里维护，避免 UI 和任务工厂各自写一份映射。
    switch (normalizeReviewType(reviewType)) {
      case ReviewTypeConstants.continuity:
        return '连续性检查';
      case ReviewTypeConstants.style:
        return '文风审稿';
      case ReviewTypeConstants.plot:
        return '剧情检查';
      default:
        return '综合检查';
    }
  }

  String reviewGoal(String reviewType) {
    // 中文注释: 目标文案是提示变量和一键任务都要复用的规则文本。
    switch (normalizeReviewType(reviewType)) {
      case ReviewTypeConstants.continuity:
        return '检查角色状态、世界规则、时间线、伏笔和前后文是否矛盾。';
      case ReviewTypeConstants.style:
        return '检查文风一致性、段落节奏、对白质感、说明化表达和 AI 腔。';
      case ReviewTypeConstants.plot:
        return '检查章节功能、冲突推进、悬念、爽点、因果链和读者期待。';
      default:
        return '综合检查文本质量、逻辑和可读性。';
    }
  }
}
