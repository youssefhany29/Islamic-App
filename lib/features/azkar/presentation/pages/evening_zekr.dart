import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'zekr_reading_page.dart';

class EveningZekr extends ZekrReadingPage {
  EveningZekr({super.key})
    : super(
        category: ZekrLocalData.categories.firstWhere(
          (category) => category.id == ZekrLocalData.eveningId,
        ),
      );
}
