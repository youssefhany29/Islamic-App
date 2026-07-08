part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderWarmupMethods on _QpcConnectedMushafPageState {
  int _mushafPageIndex(int pageNumber) {
    return QpcMushafPageView.indexFromPageNumber(pageNumber);
  }

  void _warmUpReaderAssets(int pageNumber, {required String reason}) {
    final int safePage = pageNumber.clamp(1, 604).toInt();

    if (_lastWarmUpCenterPage == safePage) {
      return;
    }

    _lastWarmUpCenterPage = safePage;
    final int generation = ++_readerWarmUpGeneration;

    unawaited(
      _prepareReaderWindow(safePage, generation: generation, reason: reason),
    );
  }

  Future<void> _prepareReaderWindow(
    int pageNumber, {
    required int generation,
    required String reason,
  }) async {
    final int safePage = pageNumber.clamp(1, 604).toInt();

    await QpcReaderPerf.timeAsync(
      'reader warm-up $reason p$safePage',
      () async {
        await _repository.initialize();

        for (final int page in _priorityReaderPages(safePage, radius: 2)) {
          if (!mounted || generation != _readerWarmUpGeneration) {
            return;
          }

          await Future.wait(<Future<dynamic>>[
            _repository.loadPage(page),
            _svgGeometryRepository.loadPage(page),
          ]);

          await Future<void>.delayed(Duration.zero);
        }

        _repository.retainPagesAround(safePage, radius: 4);
      },
    );
  }

  List<int> _priorityReaderPages(int pageNumber, {required int radius}) {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    final List<int> pages = <int>[safePage];

    for (int offset = 1; offset <= radius; offset++) {
      final int nextPage = safePage + offset;
      final int previousPage = safePage - offset;

      if (nextPage <= 604) {
        pages.add(nextPage);
      }

      if (previousPage >= 1) {
        pages.add(previousPage);
      }
    }

    return pages;
  }
}
