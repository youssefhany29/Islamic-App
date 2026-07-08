part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderSearchMethods on _QpcConnectedMushafPageState {
  Future<void> _openSearch() async {
    _showControls();

    final QpcAyahKey? target = await Navigator.of(context).push<QpcAyahKey>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return QpcAyahSearchPage(
            readerTheme: _themeController.theme,
            currentAyahKey:
                _anchorAyahKey ?? _selection?.ayahKey ?? _playingAyah,
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (target == null || !mounted) {
      return;
    }

    await QuranPageMapper.load();
    final int pageNumber = _pageNumberForAyah(target);

    if (!_connectedMode) {
      _lastMushafPageNumber = pageNumber;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_mushafPageIndex(pageNumber));
      }
    }

    setState(() {
      _anchorAyahKey = target;
      _selectedPageNumber = pageNumber;
      _selection = QuranSelection(ayahKey: target);
      _audioPanelVisible = false;
      _controlsVisible = true;
      _activeAudioWord = null;
    });

    _setBottomBarSnapshotForPage(pageNumber, ayahKey: target);
    _scheduleReadingPersistence(
      ayahKey: target,
      mushafPageNumber: pageNumber,
      wordCount: _repository.getCachedPage(pageNumber)?.allWords.length,
      recordStats: true,
      reason: 'search jump',
    );
    if (!_connectedMode) {
      _warmUpReaderAssets(pageNumber, reason: 'search jump');
    }

    _restartControlsAutoHideTimer();
  }

  Future<List<_AyahSearchResult>> _searchAyahByText(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/search/$encodedQuery/all/ar',
      );

      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) return [];

      final dynamic data = decoded['data'];
      if (data is! Map) return [];

      final dynamic matches = data['matches'];
      if (matches is! List) return [];

      final List<_AyahSearchResult> results = [];

      for (final dynamic match in matches.take(8)) {
        if (match is! Map) continue;

        final dynamic surahData = match['surah'];
        final dynamic ayahNumber = match['numberInSurah'];
        final dynamic text = match['text'];

        if (surahData is! Map) continue;

        final int? surahNumber = int.tryParse(surahData['number'].toString());
        final int? ayahNum = int.tryParse(ayahNumber.toString());

        if (surahNumber == null || ayahNum == null) continue;
        if (surahNumber < 1 || surahNumber > 114) continue;

        final int ayahCount = noOfVerses[surahNumber - 1];
        if (ayahNum < 1 || ayahNum > ayahCount) continue;

        final String surahName =
            surahData['name']?.toString() ?? 'سورة $surahNumber';

        results.add(
          _AyahSearchResult(
            ayahKey: QpcAyahKey(surah: surahNumber, ayah: ayahNum),
            displayText: '$surahName - آية $ayahNum',
            ayahText: text?.toString(),
          ),
        );
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  QpcAyahKey? _parseAyahSearch(String rawInput) {
    final Iterable<int> numbers = RegExp(r'\d+')
        .allMatches(rawInput)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>();
    final List<int> parts = numbers.toList(growable: false);

    if (parts.length < 2) {
      return null;
    }

    final int surah = parts[0];
    final int ayah = parts[1];

    if (surah < 1 || surah > 114) {
      return null;
    }

    final int ayahCount = noOfVerses[surah - 1];
    if (ayah < 1 || ayah > ayahCount) {
      return null;
    }

    return QpcAyahKey(surah: surah, ayah: ayah);
  }
}
