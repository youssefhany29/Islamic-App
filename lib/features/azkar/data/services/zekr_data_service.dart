import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import '../models/zekr_item_model.dart';
import 'zekr_custom_storage_service.dart';

class ZekrDataService {
  const ZekrDataService();

  Future<List<ZekrItemModel>> getItemsByCategory(String categoryId) async {
    if (categoryId == ZekrLocalData.customId) {
      return const ZekrCustomStorageService().getCustomAzkar();
    }

    return ZekrLocalData.getBuiltInItems(categoryId);
  }
}
