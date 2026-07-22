import 'object_detection_service.dart';

class DetectionResultFormatter {
  const DetectionResultFormatter();

  String format(List<ObjectDetection> detections) {
    if (detections.isEmpty) {
      return 'No objects detected clearly';
    }

    final grouped = <String, _DetectionGroup>{};
    for (final detection in detections) {
      final group = grouped.putIfAbsent(
        detection.label,
        () => _DetectionGroup(label: detection.label),
      );
      group
        ..count += 1
        ..bestConfidence = detection.confidence > group.bestConfidence
            ? detection.confidence
            : group.bestConfidence;
    }

    final topGroups = grouped.values.toList()
      ..sort((a, b) => b.bestConfidence.compareTo(a.bestConfidence));
    final summarized = topGroups.take(3).map(_formatGroup).toList();

    return '${_joinNaturally(summarized)} detected ahead';
  }

  String _formatGroup(_DetectionGroup group) {
    if (group.count == 1) {
      return _articleFor(group.label);
    }
    return '${_numberWord(group.count)} ${_pluralize(group.label)}';
  }

  String _articleFor(String label) {
    final article = RegExp(r'^[aeiou]', caseSensitive: false).hasMatch(label)
        ? 'an'
        : 'a';
    return '$article $label';
  }

  String _numberWord(int count) {
    const words = {
      2: 'Two',
      3: 'Three',
      4: 'Four',
      5: 'Five',
      6: 'Six',
      7: 'Seven',
      8: 'Eight',
      9: 'Nine',
      10: 'Ten',
    };
    return words[count] ?? count.toString();
  }

  String _pluralize(String label) {
    if (label.endsWith('s')) return label;
    if (label.endsWith('person')) return 'people';
    if (label.endsWith('y')) {
      return '${label.substring(0, label.length - 1)}ies';
    }
    return '${label}s';
  }

  String _joinNaturally(List<String> items) {
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items[0]}, ${items[1]}, and ${items[2]}';
  }
}

class _DetectionGroup {
  final String label;
  int count = 0;
  double bestConfidence = 0;

  _DetectionGroup({required this.label});
}
