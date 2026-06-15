import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/ordinary_conversation_task_profile.dart';
import '../models/project_opening_maturity_assessment.dart';

class OrdinaryConversationTaskProfileService {
  const OrdinaryConversationTaskProfileService();

  OrdinaryConversationTaskProfile resolve({
    required JsonMap agent,
    required ProjectOpeningMaturityAssessment openingMaturity,
    required String userPrompt,
    String activeDocumentPath = '',
  }) {
    final agentTokens = _normalized(
      <String>[
        ValueReaders.stringValue(agent['id']),
        ValueReaders.stringValue(agent['role']),
        ValueReaders.stringValue(agent['name']),
        ValueReaders.stringValue(agent['display_name']),
        ValueReaders.stringValue(agent['description']),
      ].join(' '),
    );
    final prompt = _normalized(userPrompt);
    final semanticPrompt = _semanticPrompt(prompt);
    final activePath = _normalized(activeDocumentPath);

    if (_looksLikeReview(semanticPrompt) || agentTokens.contains('review')) {
      return const OrdinaryConversationTaskProfile(
        taskType: 'review',
        intent: 'review',
      );
    }
    if (_looksLikeRevision(semanticPrompt) ||
        agentTokens.contains('recover') ||
        agentTokens.contains('repair') ||
        agentTokens.contains('修复') ||
        agentTokens.contains('恢复')) {
      return const OrdinaryConversationTaskProfile(
        taskType: 'revision',
        intent: 'revision',
      );
    }

    final planningByAgent =
        agentTokens.contains('profile') ||
        agentTokens.contains('architect') ||
        agentTokens.contains('解释器');
    final researchByAgent =
        agentTokens.contains('research') ||
        agentTokens.contains('researcher') ||
        agentTokens.contains('资料检索') ||
        agentTokens.contains('考据');
    final planningByPrompt = _looksLikePlanning(semanticPrompt);
    final researchByPrompt = _looksLikeResearch(semanticPrompt);
    final explicitChapterByPrompt = _looksLikeChapter(semanticPrompt);
    final planningByPath = _isPlanningPath(activePath);
    final chapterByPath =
        _isChapterPath(activePath) || _isScenePath(activePath);

    if ((researchByPrompt || researchByAgent) && !explicitChapterByPrompt) {
      return const OrdinaryConversationTaskProfile(
        taskType: 'research',
        intent: 'research',
      );
    }

    if (planningByPrompt && !explicitChapterByPrompt) {
      return const OrdinaryConversationTaskProfile(
        taskType: 'planning',
        intent: 'planning',
      );
    }

    if (openingMaturity.shouldShowOpeningEntry) {
      if (!explicitChapterByPrompt && !chapterByPath) {
        return const OrdinaryConversationTaskProfile(
          taskType: 'planning',
          intent: 'planning',
        );
      }
    }

    if ((planningByAgent || planningByPath) &&
        !chapterByPath &&
        !explicitChapterByPrompt) {
      return const OrdinaryConversationTaskProfile(
        taskType: 'planning',
        intent: 'planning',
      );
    }

    return const OrdinaryConversationTaskProfile(
      taskType: 'chapter',
      intent: 'draft',
    );
  }

  bool _looksLikeReview(String prompt) {
    return prompt.contains('审稿') ||
        prompt.contains('检查') ||
        prompt.contains('复核') ||
        prompt.contains('review');
  }

  bool _looksLikeRevision(String prompt) {
    return prompt.contains('修订') ||
        prompt.contains('修复') ||
        prompt.contains('改写') ||
        prompt.contains('润色') ||
        prompt.contains('重写') ||
        prompt.contains('repair') ||
        prompt.contains('rewrite');
  }

  bool _looksLikePlanning(String prompt) {
    return prompt.contains('背景') ||
        prompt.contains('概念') ||
        prompt.contains('体系') ||
        prompt.contains('能力') ||
        prompt.contains('性格') ||
        prompt.contains('处事') ||
        prompt.contains('风格') ||
        prompt.contains('规则') ||
        prompt.contains('设定') ||
        prompt.contains('世界观') ||
        prompt.contains('题材') ||
        prompt.contains('主线') ||
        prompt.contains('大纲') ||
        prompt.contains('梗概') ||
        prompt.contains('开局') ||
        prompt.contains('开篇') ||
        prompt.contains('人设') ||
        prompt.contains('角色设计') ||
        prompt.contains('角色关系') ||
        prompt.contains('剧情方向') ||
        prompt.contains('整理思路') ||
        prompt.contains('整理一下') ||
        prompt.contains('先帮我整理') ||
        prompt.contains('收束') ||
        prompt.contains('演化剧情');
  }

  bool _looksLikeResearch(String prompt) {
    return prompt.contains('资料') ||
        prompt.contains('研究') ||
        prompt.contains('联网') ||
        prompt.contains('核查') ||
        prompt.contains('考据') ||
        prompt.contains('来源') ||
        prompt.contains('知识库') ||
        prompt.contains('史料');
  }

  bool _looksLikeChapter(String prompt) {
    return prompt.contains('正文') ||
        prompt.contains('续写') ||
        prompt.contains('本章') ||
        prompt.contains('第一章') ||
        prompt.contains('第二章') ||
        prompt.contains('第三章') ||
        prompt.contains('写一章') ||
        prompt.contains('继续写');
  }

  bool _isPlanningPath(String relativePath) {
    return relativePath.startsWith('premise/') ||
        relativePath.startsWith('outlines/') ||
        relativePath.startsWith('outline/') ||
        relativePath.startsWith('chapter_outlines/') ||
        relativePath.startsWith('volume_outlines/') ||
        relativePath.startsWith('assets/');
  }

  bool _isChapterPath(String relativePath) {
    return relativePath.startsWith('chapters/');
  }

  bool _isScenePath(String relativePath) {
    return relativePath.startsWith('scenes/');
  }

  String _normalized(String value) {
    return value.trim().replaceAll('\\', '/').toLowerCase();
  }

  String _semanticPrompt(String normalizedPrompt) {
    if (normalizedPrompt.isEmpty) {
      return normalizedPrompt;
    }
    final lines = normalizedPrompt
        .split('\n')
        .map((line) => line.trim())
        .where(
          (line) =>
              line.isNotEmpty && !line.startsWith('上一轮候选摘要：'),
        )
        .toList(growable: false);
    return lines.join('\n');
  }
}
