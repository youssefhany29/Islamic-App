class MemorizationOrderingAnswerController {
  const MemorizationOrderingAnswerController();

  List<String> add(List<String> selectedIds, String optionId) {
    if (selectedIds.contains(optionId)) return List<String>.from(selectedIds);
    return <String>[...selectedIds, optionId];
  }

  List<String> remove(List<String> selectedIds, String optionId) {
    return List<String>.from(selectedIds)..remove(optionId);
  }

  List<String> reorder(
    List<String> selectedIds, {
    required int oldIndex,
    required int newIndex,
  }) {
    final result = List<String>.from(selectedIds);
    if (oldIndex < 0 || oldIndex >= result.length || result.length < 2) {
      return result;
    }
    var target = newIndex;
    if (target > oldIndex) target--;
    target = target.clamp(0, result.length - 1);
    final moved = result.removeAt(oldIndex);
    result.insert(target, moved);
    return result;
  }

  List<String> reset() => const <String>[];
}
