import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintTypeClassifier', () {
    const classifier = ConstraintTypeClassifier();

    test('recognizes expression constraint canonical and subtype forms', () {
      expect(classifier.isExpressionConstraint('expression_constraint'), isTrue);
      expect(
        classifier.isExpressionConstraint('expression_constraint.de_ai'),
        isTrue,
      );
      expect(
        classifier.isExpressionConstraint('  Expression_Constraint.De_Ai  '),
        isTrue,
      );
    });

    test('does not treat malformed expression shorthand as expression constraint', () {
      // 中文注释: 这是 "accepted but never applied" 的根因点：agent 误发 'expression'
      // （漏 _constraint）时，bridge 不会应用，因此权限策略也不应把它判为高风险表达限制。
      expect(classifier.isExpressionConstraint('expression'), isFalse);
      expect(classifier.isExpressionConstraint('de_ai'), isFalse);
      expect(classifier.isExpressionConstraint('ai_style'), isFalse);
    });

    test('recognizes chapter length variants', () {
      expect(classifier.isChapterLengthConstraint('chapter_length'), isTrue);
      expect(classifier.isChapterLengthConstraint('word_count'), isTrue);
      expect(classifier.isChapterLengthConstraint('expression_constraint'), isFalse);
    });

    test('isRecognized covers only the two handled families', () {
      expect(classifier.isRecognized('expression_constraint'), isTrue);
      expect(classifier.isRecognized('chapter_length'), isTrue);
      expect(classifier.isRecognized('style'), isFalse);
      expect(classifier.isRecognized('world_setting'), isFalse);
    });
  });
}
