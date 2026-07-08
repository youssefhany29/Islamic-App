class MemorizationSessionResultModel {
  final String id;
  final String taskId;
  final String taskType;

  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final int ayahsCount;

  /// easy / good / hard / forgot
  final String rating;

  /// reading / repeating / testing / completed
  final String completedStep;

  final int estimatedMinutes;
  final int actualMinutes;

  final bool needsRescueReview;
  final DateTime completedAt;

  const MemorizationSessionResultModel({
    required this.id,
    required this.taskId,
    required this.taskType,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.ayahsCount,
    required this.rating,
    required this.completedStep,
    required this.estimatedMinutes,
    required this.actualMinutes,
    required this.needsRescueReview,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'taskType': taskType,
      'startGlobalAyahIndex': startGlobalAyahIndex,
      'endGlobalAyahIndex': endGlobalAyahIndex,
      'ayahsCount': ayahsCount,
      'rating': rating,
      'completedStep': completedStep,
      'estimatedMinutes': estimatedMinutes,
      'actualMinutes': actualMinutes,
      'needsRescueReview': needsRescueReview,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory MemorizationSessionResultModel.fromMap(Map<String, dynamic> map) {
    return MemorizationSessionResultModel(
      id: map['id']?.toString() ?? '',
      taskId: map['taskId']?.toString() ?? '',
      taskType: map['taskType']?.toString() ?? '',
      startGlobalAyahIndex:
      int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
      int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      ayahsCount: int.tryParse(map['ayahsCount']?.toString() ?? '') ?? 0,
      rating: map['rating']?.toString() ?? 'good',
      completedStep: map['completedStep']?.toString() ?? 'completed',
      estimatedMinutes:
      int.tryParse(map['estimatedMinutes']?.toString() ?? '') ?? 0,
      actualMinutes: int.tryParse(map['actualMinutes']?.toString() ?? '') ?? 0,
      needsRescueReview: map['needsRescueReview'] == true,
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
