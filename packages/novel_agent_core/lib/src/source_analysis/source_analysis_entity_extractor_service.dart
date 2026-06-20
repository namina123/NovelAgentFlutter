import 'source_analysis_entity_rank.dart';

class SourceAnalysisEntityExtractorService {
  const SourceAnalysisEntityExtractorService();

  Map<String, int> extractHanCandidateCounts(
    String sourceContent, {
    int minOccurrences = 2,
  }) {
    final counts = <String, int>{};
    final runs = RegExp(r'[\u4E00-\u9FFF]{2,16}')
        .allMatches(sourceContent)
        .map((match) => match.group(0)!.trim())
        .where((value) => value.isNotEmpty);
    for (final run in runs) {
      final maxWindow = run.length < 4 ? run.length : 4;
      for (var window = 2; window <= maxWindow; window += 1) {
        for (var index = 0; index <= run.length - window; index += 1) {
          final candidate = run.substring(index, index + window).trim();
          if (candidate.isEmpty) {
            continue;
          }
          counts.update(candidate, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    final entries = counts.entries
        .where((entry) => entry.value >= minOccurrences)
        .toList();
    entries.sort((left, right) => right.value.compareTo(left.value));
    return Map<String, int>.fromEntries(entries);
  }

  List<SourceAnalysisEntityRank> extractLatinNamedEntities(
    String sourceText, {
    required int maxCount,
  }) {
    final counts = <String, int>{};
    const stopWords = <String>{
      'Chapter',
      'Mr',
      'Mrs',
      'The',
      'And',
      'But',
      'His',
      'Her',
      'Its',
      'Their',
      'There',
      'This',
      'That',
      'These',
      'Those',
      'Then',
      'When',
      'Where',
      'What',
      'Why',
      'How',
      'Well',
      'Now',
      'Look',
      'Come',
      'Into',
      'From',
      'With',
      'Without',
      'After',
      'Before',
      'Over',
      'Under',
      'Around',
      'About',
      'Through',
      'Because',
      'Though',
      'While',
      'Yes',
      'No',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'It',
      'He',
      'She',
      'They',
      'Them',
      'We',
      'You',
      'I',
      'A',
      'An',
    };
    final entityPattern = RegExp(r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2}\b');
    for (final match in entityPattern.allMatches(sourceText)) {
      final value = match.group(0)?.trim() ?? '';
      if (value.isEmpty || stopWords.contains(value)) {
        continue;
      }
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final ranked = counts.entries
        .where((entry) => entry.value >= 2)
        .map(
          (entry) => SourceAnalysisEntityRank(
            label: entry.key,
            count: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) {
        final countCompare = right.count.compareTo(left.count);
        if (countCompare != 0) {
          return countCompare;
        }
        return left.label.compareTo(right.label);
      });
    return ranked.take(maxCount.clamp(1, 12).toInt()).toList(growable: false);
  }
}
