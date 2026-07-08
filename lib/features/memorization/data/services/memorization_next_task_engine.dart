import '../models/memorization_session_result_model.dart';
import '../models/memorization_today_task_model.dart';

/// هذا المحرك لم يعد مسؤولًا عن تحريك مسار الحفظ.
/// سبب التغيير:
/// - الخطة الآن تُبنى من عدد الجلسات المكتملة فعليًا.
/// - لو المستخدم فوّت يومًا، الجدول يُعاد من اليوم التالي بدون ضغط.
/// - إتمام الحفظ لا يمسح مراجعة المساء.
/// - إتمام المراجعة لا يحرك مؤشر الحفظ.
///
/// تركنا نفس اسم الكلاس والدالة حتى لا نكسر الاستدعاءات القديمة
/// داخل صفحة الجلسة.
class MemorizationNextTaskEngine {
  const MemorizationNextTaskEngine();

  Future<MemorizationTodayTaskModel?> generateNextTaskAfterSession({
    required MemorizationSessionResultModel result,
  }) async {
    return null;
  }
}
