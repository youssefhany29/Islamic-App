import 'package:shared_preferences/shared_preferences.dart';

class HadithProgressService {
  const HadithProgressService();

  static const String _completedItemsPrefix = 'hadith_completed_items_';
  static const String _readCountTotalKey = 'hadith_read_count_total';
  static const String _readCountTodayPrefix = 'hadith_read_count_today_';

  String _todayKey() {
    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _storageKey() {
    return '$_completedItemsPrefix${_todayKey()}';
  }

  String _readCountTodayKey() {
    return '$_readCountTodayPrefix${_todayKey()}';
  }

  String _itemKey({required String categoryId, required String itemId}) {
    return '$categoryId::$itemId';
  }

  Future<Set<String>> getCompletedItemsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedItems = prefs.getStringList(_storageKey()) ?? [];

    return savedItems.toSet();
  }

  Future<bool> isItemCompletedToday({
    required String categoryId,
    required String itemId,
  }) async {
    final Set<String> completedItems = await getCompletedItemsToday();

    return completedItems.contains(
      _itemKey(categoryId: categoryId, itemId: itemId),
    );
  }

  Future<void> markItemCompleted({
    required String categoryId,
    required String itemId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final Set<String> completedItems = await getCompletedItemsToday();

    completedItems.add(_itemKey(categoryId: categoryId, itemId: itemId));

    await prefs.setStringList(_storageKey(), completedItems.toList());
  }

  Future<void> unmarkItemCompleted({
    required String categoryId,
    required String itemId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final Set<String> completedItems = await getCompletedItemsToday();

    completedItems.remove(_itemKey(categoryId: categoryId, itemId: itemId));

    await prefs.setStringList(_storageKey(), completedItems.toList());
  }

  Future<int> getCompletedCountForCategory(String categoryId) async {
    final Set<String> completedItems = await getCompletedItemsToday();

    return completedItems
        .where((key) => key.startsWith('$categoryId::'))
        .length;
  }

  /// هذا العداد ليس عدد الأحاديث الموجودة في التطبيق.
  /// هذا هو عدد المرات التي فتح/قرأ فيها المستخدم حديثًا.
  Future<void> recordHadithRead({String? categoryId, String? itemId}) async {
    final prefs = await SharedPreferences.getInstance();

    final int total = prefs.getInt(_readCountTotalKey) ?? 0;
    final int today = prefs.getInt(_readCountTodayKey()) ?? 0;

    await prefs.setInt(_readCountTotalKey, total + 1);
    await prefs.setInt(_readCountTodayKey(), today + 1);
  }

  Future<int> getTotalReadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_readCountTotalKey) ?? 0;
  }

  Future<int> getTodayReadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_readCountTodayKey()) ?? 0;
  }

  Future<void> resetReadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readCountTotalKey);
    await prefs.remove(_readCountTodayKey());
  }
}
