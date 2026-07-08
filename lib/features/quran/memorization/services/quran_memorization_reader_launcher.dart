import 'package:flutter/material.dart';

import '../../reader/hiding/quran_hide_mode.dart';
import '../../reader/qpc_connected_mushaf_page.dart';
import '../../reader/quran_page_mapper.dart';
import '../../reader/quran_reader_helpers.dart';
import '../models/quran_memorization_task_model.dart';
import 'quran_memorization_progress_storage.dart';

class QuranMemorizationReaderLauncher {
  const QuranMemorizationReaderLauncher();

  Future<void> openTaskReader({
    required BuildContext context,
    required QuranMemorizationTaskModel task,
    String initialStep = 'reading',
  }) async {
    if (!task.isValidRange) {
      _showErrorSnackBar(context: context, message: 'مهمة الحفظ غير صحيحة');
      return;
    }

    await QuranPageMapper.load();

    final savedProgress = await QuranMemorizationProgressStorage.getProgress(
      task.id,
    );

    if (!context.mounted) return;

    final int taskStartGlobalAyahIndex = task.startGlobalAyahIndex;
    final int taskEndGlobalAyahIndex = task.endGlobalAyahIndex;

    int clampInsideTask(int globalAyahIndex) {
      return globalAyahIndex
          .clamp(taskStartGlobalAyahIndex, taskEndGlobalAyahIndex)
          .toInt();
    }

    int safePageNumberFromGlobal(int globalAyahIndex) {
      final page = QuranPageMapper.getPageNumberForGlobalAyah(globalAyahIndex);
      return page.clamp(1, 604).toInt();
    }

    int globalFromProgress(QuranMemorizationProgress progress) {
      final fromSuraAndAyah = QuranReaderHelpers.getGlobalAyahIndex(
        suraIndex: progress.suraIndex,
        ayahIndex: progress.ayahIndex,
      );

      final bool validFromSuraAndAyah =
          fromSuraAndAyah >= 0 &&
          fromSuraAndAyah < QuranReaderHelpers.totalAyahs;

      if (validFromSuraAndAyah) {
        return fromSuraAndAyah;
      }

      return progress.globalAyahIndex;
    }

    int resumeGlobalAyahIndex = taskStartGlobalAyahIndex;
    String currentStep = initialStep.trim().isEmpty ? 'reading' : initialStep;

    if (savedProgress != null) {
      final savedGlobalAyahIndex = globalFromProgress(savedProgress);

      final bool savedProgressInsideTask =
          savedGlobalAyahIndex >= taskStartGlobalAyahIndex &&
          savedGlobalAyahIndex <= taskEndGlobalAyahIndex;

      if (savedProgressInsideTask) {
        resumeGlobalAyahIndex = clampInsideTask(savedGlobalAyahIndex);
        currentStep = savedProgress.step.trim().isEmpty
            ? 'reading'
            : savedProgress.step;
      } else {
        await QuranMemorizationProgressStorage.clearProgress(task.id);
        resumeGlobalAyahIndex = taskStartGlobalAyahIndex;
        currentStep = initialStep.trim().isEmpty ? 'reading' : initialStep;
      }
    }

    resumeGlobalAyahIndex = clampInsideTask(resumeGlobalAyahIndex);

    final resumePosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      resumeGlobalAyahIndex,
    );

    final int initialMushafPageNumber = safePageNumberFromGlobal(
      resumeGlobalAyahIndex,
    );

    await QuranMemorizationProgressStorage.saveProgress(
      taskId: task.id,
      suraIndex: resumePosition.suraIndex,
      ayahIndex: resumePosition.ayahIndex,
      globalAyahIndex: resumeGlobalAyahIndex,
      mushafPageNumber: initialMushafPageNumber,
      viewMode: 'qpc_connected',
      step: currentStep,
    );

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QpcConnectedMushafPage(
          initialPage: initialMushafPageNumber,
          initialGlobalAyahIndex: resumeGlobalAyahIndex,
          initialHideMode: currentStep == 'testing'
              ? QuranHideMode.full
              : QuranHideMode.visible,
          openedFromTest: currentStep == 'testing',
          saveAsLastRead: false,
          saveAsMushafOpenProgress: false,
          memorizationTaskId: task.id,
          memorizationStartGlobalAyahIndex: task.startGlobalAyahIndex,
          memorizationEndGlobalAyahIndex: task.endGlobalAyahIndex,
          memorizationStep: currentStep,
        ),
      ),
    );
  }

  void _showErrorSnackBar({
    required BuildContext context,
    required String message,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          message,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
