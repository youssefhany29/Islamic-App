import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import '../models/zekr_item_model.dart';

class ZekrCustomStorageService {
  const ZekrCustomStorageService();

  static const String _customAzkarKey = 'custom_azkar_items';

  Future<List<ZekrItemModel>> getCustomAzkar() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString(_customAzkarKey);

    if (rawData == null || rawData.trim().isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;

    return decoded
        .map((item) => ZekrItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCustomZekr({
    required String text,
    String? title,
    String? benefit,
    int count = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ZekrItemModel> currentItems = await getCustomAzkar();

    final ZekrItemModel newItem = ZekrItemModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: ZekrLocalData.customId,
      title: title == null || title.trim().isEmpty ? null : title.trim(),
      text: text.trim(),
      count: count,
      benefit: benefit == null || benefit.trim().isEmpty
          ? null
          : benefit.trim(),
      isCustom: true,
      type: ZekrType.general,
    );

    final List<ZekrItemModel> updatedItems = [newItem, ...currentItems];

    await _saveCustomAzkar(prefs: prefs, items: updatedItems);
  }

  Future<void> updateCustomZekr({
    required String id,
    required String text,
    String? title,
    String? benefit,
    int count = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ZekrItemModel> currentItems = await getCustomAzkar();

    final List<ZekrItemModel> updatedItems = currentItems.map((item) {
      if (item.id != id) return item;

      return item.copyWith(
        title: title == null || title.trim().isEmpty ? null : title.trim(),
        text: text.trim(),
        count: count <= 0 ? 1 : count,
        benefit: benefit == null || benefit.trim().isEmpty
            ? null
            : benefit.trim(),
        isCustom: true,
        type: ZekrType.general,
      );
    }).toList();

    await _saveCustomAzkar(prefs: prefs, items: updatedItems);
  }

  Future<void> deleteCustomZekr(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ZekrItemModel> currentItems = await getCustomAzkar();

    final List<ZekrItemModel> updatedItems = currentItems
        .where((item) => item.id != id)
        .toList();

    await _saveCustomAzkar(prefs: prefs, items: updatedItems);
  }

  Future<void> reorderCustomAzkar(List<ZekrItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();

    await _saveCustomAzkar(prefs: prefs, items: items);
  }

  Future<void> _saveCustomAzkar({
    required SharedPreferences prefs,
    required List<ZekrItemModel> items,
  }) async {
    await prefs.setString(
      _customAzkarKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
