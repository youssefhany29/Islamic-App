import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/features/hadith/data/datasources/hadith_local_data.dart';
import '../models/hadith_item_model.dart';

class HadithCustomStorageService {
  const HadithCustomStorageService();

  static const String _customHadithKey = 'custom_hadith_items';

  // مفاتيح قديمة للتوافق لو كان فيه بيانات محفوظة من نسخة سابقة.
  static const String _legacyCustomAzkarKey = 'custom_azkar_items';

  Future<List<HadithItemModel>> getCustomAzkar() async {
    return getCustomHadiths();
  }

  Future<List<HadithItemModel>> getCustomHadiths() async {
    final prefs = await SharedPreferences.getInstance();

    String? rawData = prefs.getString(_customHadithKey);

    rawData ??= prefs.getString(_legacyCustomAzkarKey);

    if (rawData == null || rawData.trim().isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;

    return decoded
        .map((item) => HadithItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<HadithItemModel>> getCustomHadithsByCategory(
    String categoryId,
  ) async {
    final items = await getCustomHadiths();

    return items.where((item) => item.categoryId == categoryId).toList();
  }

  Future<void> addCustomHadith({
    required String text,
    String? title,
    String? benefit,
    String? lesson,
    String? source,
    String? reference,
    String? grade,
    String? book,
    String? chapter,
    String? categoryId,
    int count = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<HadithItemModel> currentItems = await getCustomHadiths();

    final HadithItemModel newItem = HadithItemModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: categoryId ?? HadithLocalData.customId,
      title: title == null || title.trim().isEmpty ? null : title.trim(),
      text: text.trim(),
      count: count <= 0 ? 1 : count,
      source: source == null || source.trim().isEmpty ? null : source.trim(),
      reference: reference == null || reference.trim().isEmpty
          ? null
          : reference.trim(),
      grade: grade == null || grade.trim().isEmpty ? null : grade.trim(),
      book: book == null || book.trim().isEmpty ? null : book.trim(),
      chapter: chapter == null || chapter.trim().isEmpty
          ? null
          : chapter.trim(),
      benefit: benefit == null || benefit.trim().isEmpty
          ? null
          : benefit.trim(),
      lesson: lesson == null || lesson.trim().isEmpty ? null : lesson.trim(),
      isCustom: true,
      type: HadithType.hadith,
    );

    final List<HadithItemModel> updatedItems = [newItem, ...currentItems];

    await _saveCustomHadiths(prefs: prefs, items: updatedItems);
  }

  Future<void> updateCustomHadith({
    required String id,
    required String text,
    String? title,
    String? benefit,
    String? lesson,
    String? source,
    String? reference,
    String? grade,
    String? book,
    String? chapter,
    String? categoryId,
    int count = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<HadithItemModel> currentItems = await getCustomHadiths();

    final List<HadithItemModel> updatedItems = currentItems.map((item) {
      if (item.id != id) return item;

      return item.copyWith(
        categoryId: categoryId ?? item.categoryId,
        title: title == null || title.trim().isEmpty ? null : title.trim(),
        text: text.trim(),
        count: count <= 0 ? 1 : count,
        source: source == null || source.trim().isEmpty ? null : source.trim(),
        reference: reference == null || reference.trim().isEmpty
            ? null
            : reference.trim(),
        grade: grade == null || grade.trim().isEmpty ? null : grade.trim(),
        book: book == null || book.trim().isEmpty ? null : book.trim(),
        chapter: chapter == null || chapter.trim().isEmpty
            ? null
            : chapter.trim(),
        benefit: benefit == null || benefit.trim().isEmpty
            ? null
            : benefit.trim(),
        lesson: lesson == null || lesson.trim().isEmpty ? null : lesson.trim(),
        isCustom: true,
        type: HadithType.hadith,
      );
    }).toList();

    await _saveCustomHadiths(prefs: prefs, items: updatedItems);
  }

  Future<void> deleteCustomHadith(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<HadithItemModel> currentItems = await getCustomHadiths();

    final List<HadithItemModel> updatedItems = currentItems
        .where((item) => item.id != id)
        .toList();

    await _saveCustomHadiths(prefs: prefs, items: updatedItems);
  }

  Future<void> reorderCustomAzkar(List<HadithItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();

    await _saveCustomHadiths(prefs: prefs, items: items);
  }

  Future<void> _saveCustomHadiths({
    required SharedPreferences prefs,
    required List<HadithItemModel> items,
  }) async {
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());

    await prefs.setString(_customHadithKey, encoded);

    // نحفظ برضه على المفتاح القديم للتوافق مع أي صفحة لسه بتقرأ الاسم القديم.
    await prefs.setString(_legacyCustomAzkarKey, encoded);
  }
}
