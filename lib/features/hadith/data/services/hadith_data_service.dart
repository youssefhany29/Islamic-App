import 'package:islamic_app/features/hadith/data/datasources/hadith_local_data.dart';
import '../models/hadith_item_model.dart';
import 'hadith_custom_storage_service.dart';

class HadithDataService {
  const HadithDataService();

  Future<List<HadithItemModel>> getItemsByCategory(String categoryId) async {
    final customService = const HadithCustomStorageService();

    if (categoryId == HadithLocalData.customId) {
      return customService.getCustomAzkar();
    }

    final builtInItems = HadithLocalData.getBuiltInItems(categoryId);
    final customItems = await customService.getCustomHadithsByCategory(
      categoryId,
    );

    return [...customItems, ...builtInItems];
  }
}
