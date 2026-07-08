class QuranMemorizationTaskModel {
  final String id;

  /// الأنواع المقترحة:
  /// newMemorization / review / test / rescue
  final String type;

  /// حدود المهمة داخل القرآن كله بالـ global ayah index.
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;

  final String title;
  final String subtitle;

  final int estimatedMinutes;
  final DateTime dueDate;

  const QuranMemorizationTaskModel({
    required this.id,
    required this.type,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.title,
    required this.subtitle,
    required this.estimatedMinutes,
    required this.dueDate,
  });

  bool get isValidRange {
    return id.trim().isNotEmpty &&
        startGlobalAyahIndex >= 0 &&
        endGlobalAyahIndex >= startGlobalAyahIndex;
  }

  int get ayahsCount {
    return endGlobalAyahIndex - startGlobalAyahIndex + 1;
  }

  bool containsGlobalAyah(int globalAyahIndex) {
    return globalAyahIndex >= startGlobalAyahIndex &&
        globalAyahIndex <= endGlobalAyahIndex;
  }

  int clampGlobalAyahIndex(int globalAyahIndex) {
    return globalAyahIndex.clamp(
      startGlobalAyahIndex,
      endGlobalAyahIndex,
    ).toInt();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'startGlobalAyahIndex': startGlobalAyahIndex,
      'endGlobalAyahIndex': endGlobalAyahIndex,
      'title': title,
      'subtitle': subtitle,
      'estimatedMinutes': estimatedMinutes,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  factory QuranMemorizationTaskModel.fromMap(Map<String, dynamic> map) {
    return QuranMemorizationTaskModel(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'newMemorization',
      startGlobalAyahIndex:
      int.tryParse(map['startGlobalAyahIndex']?.toString() ?? '') ?? 0,
      endGlobalAyahIndex:
      int.tryParse(map['endGlobalAyahIndex']?.toString() ?? '') ?? 0,
      title: map['title']?.toString() ?? 'مهمة حفظ',
      subtitle: map['subtitle']?.toString() ?? '',
      estimatedMinutes:
      int.tryParse(map['estimatedMinutes']?.toString() ?? '') ?? 10,
      dueDate: DateTime.tryParse(map['dueDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  QuranMemorizationTaskModel copyWith({
    String? id,
    String? type,
    int? startGlobalAyahIndex,
    int? endGlobalAyahIndex,
    String? title,
    String? subtitle,
    int? estimatedMinutes,
    DateTime? dueDate,
  }) {
    return QuranMemorizationTaskModel(
      id: id ?? this.id,
      type: type ?? this.type,
      startGlobalAyahIndex:
      startGlobalAyahIndex ?? this.startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex ?? this.endGlobalAyahIndex,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}