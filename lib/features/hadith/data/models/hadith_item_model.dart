enum HadithType { hadith, qudsi, dua, adab }

class HadithItemModel {
  const HadithItemModel({
    required this.id,
    required this.categoryId,
    required this.text,
    this.title,
    this.count = 1,
    this.source,
    this.reference,
    this.benefit,
    this.lesson,
    this.grade,
    this.book,
    this.chapter,
    this.isCustom = false,
    this.isQuranVerse = false,
    this.type = HadithType.hadith,
  });

  final String id;
  final String categoryId;
  final String? title;
  final String text;
  final int count;

  /// اسم المصدر المختصر مثل: صحيح البخاري، صحيح مسلم، رياض الصالحين.
  final String? source;

  /// رقم الحديث أو الباب أو التخريج المختصر.
  final String? reference;

  /// ماذا يضيف الحديث لحياة المستخدم.
  final String? benefit;

  /// الدرس العملي المستفاد من الحديث.
  final String? lesson;

  /// درجة الحديث إن وجدت.
  final String? grade;

  final String? book;
  final String? chapter;
  final bool isCustom;

  /// موجود للتوافق مع بعض الكروت المشتركة، وسيكون غالبًا false في الأحاديث.
  final bool isQuranVerse;

  final HadithType type;

  String get actionButtonLabel {
    switch (type) {
      case HadithType.hadith:
        return 'قرأت الحديث';
      case HadithType.qudsi:
        return 'قرأت الحديث';
      case HadithType.dua:
        return 'دعوت مرة';
      case HadithType.adab:
        return 'طبّقت المعنى';
    }
  }

  String get completedLabel {
    switch (type) {
      case HadithType.hadith:
      case HadithType.qudsi:
        return 'تمت القراءة';
      case HadithType.dua:
        return 'تم الدعاء';
      case HadithType.adab:
        return 'تم التطبيق';
    }
  }

  HadithItemModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? text,
    int? count,
    String? source,
    String? reference,
    String? benefit,
    String? lesson,
    String? grade,
    String? book,
    String? chapter,
    bool? isCustom,
    bool? isQuranVerse,
    HadithType? type,
  }) {
    return HadithItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      text: text ?? this.text,
      count: count ?? this.count,
      source: source ?? this.source,
      reference: reference ?? this.reference,
      benefit: benefit ?? this.benefit,
      lesson: lesson ?? this.lesson,
      grade: grade ?? this.grade,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
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
      'lesson': lesson,
      'grade': grade,
      'book': book,
      'chapter': chapter,
      'isCustom': isCustom,
      'isQuranVerse': isQuranVerse,
      'type': type.name,
    };
  }

  factory HadithItemModel.fromJson(Map<String, dynamic> json) {
    final String rawType = json['type'] as String? ?? HadithType.hadith.name;

    return HadithItemModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      count: json['count'] as int? ?? 1,
      source: json['source'] as String?,
      reference: json['reference'] as String?,
      benefit: json['benefit'] as String?,
      lesson: json['lesson'] as String?,
      grade: json['grade'] as String?,
      book: json['book'] as String?,
      chapter: json['chapter'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      isQuranVerse: json['isQuranVerse'] as bool? ?? false,
      type: HadithType.values.firstWhere(
        (item) => item.name == rawType,
        orElse: () => HadithType.hadith,
      ),
    );
  }
}
