enum ZekrType { quran, dua, tasbeeh, general }

class ZekrItemModel {
  const ZekrItemModel({
    required this.id,
    required this.categoryId,
    required this.text,
    this.title,
    this.count = 1,
    this.source,
    this.reference,
    this.benefit,
    this.isCustom = false,
    this.isQuranVerse = false,
    this.type = ZekrType.general,
  });

  final String id;
  final String categoryId;
  final String? title;
  final String text;
  final int count;

  /// للأحاديث أو المصدر العام، وليس للآيات.
  final String? source;

  /// للآيات والسور: سورة البقرة، الآية 255
  final String? reference;

  final String? benefit;
  final bool isCustom;
  final bool isQuranVerse;
  final ZekrType type;

  String get actionButtonLabel {
    switch (type) {
      case ZekrType.quran:
        return 'قرأت مرة';
      case ZekrType.dua:
        return 'دعوت مرة';
      case ZekrType.tasbeeh:
        return 'سبّحت مرة';
      case ZekrType.general:
        return 'ذكرت مرة';
    }
  }

  String get completedLabel {
    switch (type) {
      case ZekrType.quran:
        return 'تمت القراءة';
      case ZekrType.dua:
        return 'تم الدعاء';
      case ZekrType.tasbeeh:
        return 'تم التسبيح';
      case ZekrType.general:
        return 'تم الذكر';
    }
  }

  ZekrItemModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? text,
    int? count,
    String? source,
    String? reference,
    String? benefit,
    bool? isCustom,
    bool? isQuranVerse,
    ZekrType? type,
  }) {
    return ZekrItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      text: text ?? this.text,
      count: count ?? this.count,
      source: source ?? this.source,
      reference: reference ?? this.reference,
      benefit: benefit ?? this.benefit,
      isCustom: isCustom ?? this.isCustom,
      isQuranVerse: isQuranVerse ?? this.isQuranVerse,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'text': text,
      'count': count,
      'source': source,
      'reference': reference,
      'benefit': benefit,
      'isCustom': isCustom,
      'isQuranVerse': isQuranVerse,
      'type': type.name,
    };
  }

  factory ZekrItemModel.fromJson(Map<String, dynamic> json) {
    final String rawType = json['type'] as String? ?? ZekrType.general.name;

    return ZekrItemModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      count: json['count'] as int? ?? 1,
      source: json['source'] as String?,
      reference: json['reference'] as String?,
      benefit: json['benefit'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      isQuranVerse: json['isQuranVerse'] as bool? ?? false,
      type: ZekrType.values.firstWhere(
        (item) => item.name == rawType,
        orElse: () => ZekrType.general,
      ),
    );
  }
}
