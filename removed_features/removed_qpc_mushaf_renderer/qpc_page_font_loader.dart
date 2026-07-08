import 'package:flutter/services.dart';

import 'qpc_reader_perf.dart';

class QpcPageFontLoader {
  QpcPageFontLoader._();

  static final QpcPageFontLoader instance = QpcPageFontLoader._();

  final Set<int> _loadedPages = <int>{};
  final Map<int, Future<void>> _runningLoads = <int, Future<void>>{};

  static String familyForPage(int pageNumber) {
    return 'QpcPageFont$pageNumber';
  }

  Future<void> ensureLoaded(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      return Future<void>.value();
    }

    if (_loadedPages.contains(pageNumber)) {
      return Future<void>.value();
    }

    final Future<void>? runningLoad = _runningLoads[pageNumber];
    if (runningLoad != null) {
      return runningLoad;
    }

    final Future<void> task = _loadPageFont(pageNumber);
    _runningLoads[pageNumber] = task;

    return task;
  }

  Future<void> preloadAround(int pageNumber, {int radius = 2}) async {
    final int safePageNumber = pageNumber.clamp(1, 604);
    final List<Future<void>> loads = <Future<void>>[];

    for (
      int page = safePageNumber - radius;
      page <= safePageNumber + radius;
      page++
    ) {
      if (page >= 1 && page <= 604) {
        loads.add(ensureLoaded(page));
      }
    }

    await Future.wait(loads);
  }

  bool isLoaded(int pageNumber) {
    return _loadedPages.contains(pageNumber);
  }

  Future<void> _loadPageFont(int pageNumber) async {
    final Stopwatch? stopwatch = QpcReaderPerf.start();

    try {
      final String family = familyForPage(pageNumber);
      final FontLoader loader = FontLoader(family);

      loader.addFont(rootBundle.load('assets/fonts/qpc/p$pageNumber.ttf'));

      await loader.load();

      _loadedPages.add(pageNumber);
    } finally {
      _runningLoads.remove(pageNumber);
      QpcReaderPerf.end('font load p$pageNumber', stopwatch);
    }
  }
}
