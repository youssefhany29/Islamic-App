import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import '../audio/quran_ayah_audio_service.dart';

class QpcExactExperimentPage extends StatefulWidget {
  const QpcExactExperimentPage({
    super.key,
    this.initialPage = 1,
  });

  final int initialPage;

  @override
  State<QpcExactExperimentPage> createState() => _QpcExactExperimentPageState();
}

class _QpcExactExperimentPageState extends State<QpcExactExperimentPage> {
  late final PageController _pageController;

  final QuranAyahAudioService _audioService = QuranAyahAudioService.instance;

  int _selectedPageNumber = 1;
  bool _controlsVisible = true;
  bool _isAudioLoading = false;

  QpcAyahKey? _selectedAyah;
  QpcWordKey? _selectedWord;
  QpcAyahKey? _playingAyah;
  QuranAyahAudioInfo? _currentAudioInfo;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();

    _selectedPageNumber = widget.initialPage.clamp(1, 604);

    _pageController = PageController(
      initialPage: _selectedPageNumber - 1,
    );

    _positionSubscription = _audioService.positionStream.listen(
      _syncWordHighlightWithAudio,
    );

    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }

      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingAyah = null;
          _currentAudioInfo = null;
        });
      }
    });
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_audioService.stop());
    _pageController.dispose();
    super.dispose();
  }

  void _syncWordHighlightWithAudio(Duration position) {
    final QuranAyahAudioInfo? info = _currentAudioInfo;
    final QpcAyahKey? playingAyah = _playingAyah;

    if (info == null || playingAyah == null || info.segments.isEmpty) {
      return;
    }

    final int positionMs = position.inMilliseconds;
    QuranWordAudioSegment? activeSegment;

    for (final QuranWordAudioSegment segment in info.segments) {
      if (positionMs >= segment.startMs && positionMs <= segment.endMs) {
        activeSegment = segment;
        break;
      }
    }

    if (activeSegment == null) {
      return;
    }

    // الـ segments في ملفات ترتيل غالبًا 0-based range مثل [0, 1, start, end].
    // كلمة QPC في قاعدة qpc-v2.db 1-based، لذلك نستخدم toWord لأنه يساوي رقم الكلمة.
    final int wordNumber = activeSegment.toWord > 0
        ? activeSegment.toWord
        : activeSegment.fromWord + 1;

    final QpcWordKey nextWord = QpcWordKey(
      surah: playingAyah.surah,
      ayah: playingAyah.ayah,
      word: wordNumber,
    );

    if (_selectedWord?.surah == nextWord.surah &&
        _selectedWord?.ayah == nextWord.ayah &&
        _selectedWord?.word == nextWord.word) {
      return;
    }

    setState(() {
      _selectedWord = nextWord;
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
  }

  void _jumpToPage(int page) {
    final int safePage = page.clamp(1, 604);

    _pageController.jumpToPage(safePage - 1);

    setState(() {
      _selectedPageNumber = safePage;
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _selectedPageNumber = page;
    });
  }

  Future<void> _onAyahTap(QpcAyahKey ayahKey) async {
    AppHaptics.tap(context);

    setState(() {
      _selectedAyah = ayahKey;
      _playingAyah = ayahKey;
      _isAudioLoading = true;
    });

    try {
      final QuranAyahAudioInfo? info = await _audioService.playAyah(
        surahNumber: ayahKey.surah,
        ayahNumber: ayahKey.ayah,
      );

      if (!mounted) {
        return;
      }

      if (info == null) {
        setState(() {
          _playingAyah = null;
          _currentAudioInfo = null;
        });

        _showAudioSnackBar(
          message: 'لم يتم العثور على صوت الآية ${ayahKey.surah}:${ayahKey.ayah}',
          isError: true,
        );

        return;
      }

      setState(() {
        _currentAudioInfo = info;
      });

      _syncWordHighlightWithAudio(Duration.zero);

      _showAudioSnackBar(
        message:
        'تم تشغيل الآية ${ayahKey.surah}:${ayahKey.ayah} — عدد مقاطع الكلمات: ${info.segments.length}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playingAyah = null;
        _currentAudioInfo = null;
      });

      _showAudioSnackBar(
        message: 'حصل خطأ أثناء تشغيل الصوت: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _onWordTap(QpcWord word) async {
    setState(() {
      _selectedWord = QpcWordKey(
        surah: word.surah,
        ayah: word.ayah,
        word: word.word,
      );
    });

    await _onAyahTap(
      QpcAyahKey(
        surah: word.surah,
        ayah: word.ayah,
      ),
    );
  }

  Future<void> _stopAudio() async {
    await _audioService.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _playingAyah = null;
      _currentAudioInfo = null;
      _isAudioLoading = false;
    });

    _showAudioSnackBar(
      message: 'تم إيقاف الصوت',
    );
  }

  void _showAudioSnackBar({
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xff005349),
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'cairo',
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pageBackgroundColor = isDark
        ? const Color(0xff071817)
        : const Color(0xffFFFDF6);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: QpcExactMushafView(
          pageController: _pageController,
          selectedPageNumber: _selectedPageNumber,
          selectedAyah: _selectedAyah,
          selectedWord: _selectedWord,
          playingAyah: _playingAyah,
          isAudioLoading: _isAudioLoading,
          onStopAudio: _stopAudio,
          onAyahTap: _onAyahTap,
          onWordTap: _onWordTap,
          onPageChanged: _onPageChanged,
          onJumpToPage: _jumpToPage,
          isDark: isDark,
          controlsVisible: _controlsVisible,
          onToggleControls: _toggleControls,
          currentSuraName: 'QPC',
          currentJuzNumber: 1,
        ),
      ),
    );
  }
}

class QpcExactMushafView extends StatefulWidget {
  const QpcExactMushafView({
    super.key,
    required this.pageController,
    required this.selectedPageNumber,
    required this.onPageChanged,
    required this.onJumpToPage,
    required this.isDark,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.currentSuraName,
    required this.currentJuzNumber,
    required this.selectedAyah,
    required this.selectedWord,
    required this.playingAyah,
    required this.isAudioLoading,
    required this.onStopAudio,
    required this.onAyahTap,
    required this.onWordTap,
  });

  final PageController pageController;
  final int selectedPageNumber;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onJumpToPage;
  final bool isDark;
  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final String currentSuraName;
  final int currentJuzNumber;
  final QpcAyahKey? selectedAyah;
  final QpcWordKey? selectedWord;
  final QpcAyahKey? playingAyah;
  final bool isAudioLoading;
  final VoidCallback onStopAudio;
  final Future<void> Function(QpcAyahKey ayahKey) onAyahTap;
  final Future<void> Function(QpcWord word) onWordTap;

  static const int firstPageNumber = 1;
  static const int totalPages = 604;

  @override
  State<QpcExactMushafView> createState() => _QpcExactMushafViewState();
}

class _QpcExactMushafViewState extends State<QpcExactMushafView> {
  final QpcMushafRepository _repository = QpcMushafRepository.instance;
  final QpcPageFontLoader _fontLoader = QpcPageFontLoader.instance;

  final Map<int, Future<QpcPageData>> _pageFutureCache =
  <int, Future<QpcPageData>>{};

  @override
  void initState() {
    super.initState();
    _warmUpAround(widget.selectedPageNumber);
  }

  @override
  void didUpdateWidget(covariant QpcExactMushafView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPageNumber != widget.selectedPageNumber) {
      _warmUpAround(widget.selectedPageNumber);
    }
  }

  Future<QpcPageData> _getPageFuture(int pageNumber) {
    return _pageFutureCache.putIfAbsent(pageNumber, () async {
      await Future.wait(<Future<void>>[
        _fontLoader.ensureLoaded(pageNumber),
        QpcCommonFontLoader.instance.ensureLoaded(),
      ]);
      return _repository.loadPage(pageNumber);
    });
  }

  void _warmUpAround(int pageNumber) {
    _getPageFuture(pageNumber);

    for (int page = pageNumber - 2; page <= pageNumber + 2; page++) {
      if (page >= 1 && page <= 604) {
        _getPageFuture(page);
      }
    }

    _fontLoader.preloadAround(pageNumber, radius: 6);
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isDark
        ? const Color(0xff071817)
        : const Color(0xffFFFDF6);
    final double pageControlsBottom = 28.h;

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: 20.h,
                bottom: 0,
              ),
              child: PageView.builder(
                reverse: true,
                controller: widget.pageController,
                itemCount: QpcExactMushafView.totalPages,
                onPageChanged: (pageIndex) {
                  widget.onPageChanged(
                    pageIndex + QpcExactMushafView.firstPageNumber,
                  );
                },
                itemBuilder: (context, pageIndex) {
                  final int pageNumber =
                      pageIndex + QpcExactMushafView.firstPageNumber;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.tap(context);
                      widget.onToggleControls();
                    },
                    child: _QpcFontPage(
                      pageNumber: pageNumber,
                      backgroundColor: backgroundColor,
                      isDark: widget.isDark,
                      selectedAyah: widget.selectedAyah,
                      selectedWord: widget.selectedWord,
                      onAyahTap: widget.onAyahTap,
                      onWordTap: widget.onWordTap,
                      pageFuture: _getPageFuture(pageNumber),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StaticMushafHeader(
              suraName: widget.currentSuraName,
              juzNumber: widget.currentJuzNumber,
              isDark: widget.isDark,
            ),
          ),
          Positioned(
            left: widget.selectedPageNumber.isEven ? 14.w : null,
            right: widget.selectedPageNumber.isOdd ? 14.w : null,
            bottom: 1.h,
            child: _IslamicPageNumberBadge(
              pageNumber: widget.selectedPageNumber,
              isDark: widget.isDark,
            ),
          ),
          if (widget.playingAyah != null || widget.isAudioLoading)
            Positioned(
              left: 12.w,
              right: 12.w,
              bottom: pageControlsBottom + 46.h,
              child: _QpcAudioMiniBar(
                ayahKey: widget.playingAyah,
                isLoading: widget.isAudioLoading,
                onStop: widget.onStopAudio,
              ),
            ),
          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: pageControlsBottom,
            child: IgnorePointer(
              ignoring: !widget.controlsVisible,
              child: AnimatedOpacity(
                opacity: widget.controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: _MushafPageControls(
                  selectedPageNumber: widget.selectedPageNumber,
                  currentSuraName: widget.currentSuraName,
                  currentJuzNumber: widget.currentJuzNumber,
                  isDark: widget.isDark,
                  onJumpToPage: widget.onJumpToPage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QpcFontPage extends StatelessWidget {
  const _QpcFontPage({
    required this.pageNumber,
    required this.backgroundColor,
    required this.isDark,
    required this.selectedAyah,
    required this.selectedWord,
    required this.onAyahTap,
    required this.onWordTap,
    required this.pageFuture,
  });

  final int pageNumber;
  final Color backgroundColor;
  final bool isDark;
  final QpcAyahKey? selectedAyah;
  final QpcWordKey? selectedWord;
  final Future<void> Function(QpcAyahKey ayahKey) onAyahTap;
  final Future<void> Function(QpcWord word) onWordTap;
  final Future<QpcPageData> pageFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: FutureBuilder<QpcPageData>(
        future: pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _MissingMushafPage(
              pageNumber: pageNumber,
              isDark: isDark,
              message: snapshot.error?.toString(),
            );
          }

          return _QpcPageContent(
            pageData: snapshot.data!,
            isDark: isDark,
            selectedAyah: selectedAyah,
            selectedWord: selectedWord,
            onAyahTap: onAyahTap,
            onWordTap: onWordTap,
          );
        },
      ),
    );
  }
}

class _QpcPageContent extends StatelessWidget {
  const _QpcPageContent({
    required this.pageData,
    required this.isDark,
    required this.selectedAyah,
    required this.selectedWord,
    required this.onAyahTap,
    required this.onWordTap,
  });

  final QpcPageData pageData;
  final bool isDark;
  final QpcAyahKey? selectedAyah;
  final QpcWordKey? selectedWord;
  final Future<void> Function(QpcAyahKey ayahKey) onAyahTap;
  final Future<void> Function(QpcWord word) onWordTap;

  @override
  Widget build(BuildContext context) {
    final String fontFamily =
    QpcPageFontLoader.familyForPage(pageData.pageNumber);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double pageWidth = constraints.maxWidth;
        final double pageHeight = constraints.maxHeight;

        final double horizontalPadding = 14.w;
        final double topPadding = 8.h;
        final double bottomPadding = 24.h;

        final double availableHeight = pageHeight - topPadding - bottomPadding;

        // مهم جدًا: مصحف QPC مبني على 15 سطر ثابت.
        // أي محاولة لتكبير سطر الهيدر على حساب باقي السطور بتبوظ صفحات كثيرة،
        // خصوصًا الصفحات التي فيها أكثر من سورة أو سطور قصيرة.
        final double lineHeight = availableHeight / 15.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Column(
            children: List.generate(15, (index) {
              final int lineNumber = index + 1;
              final QpcMushafLine? line = pageData.lineByNumber(lineNumber);

              return SizedBox(
                width: pageWidth,
                height: lineHeight,
                child: _QpcLineView(
                  line: line,
                  fontFamily: fontFamily,
                  lineHeight: lineHeight,
                  isDark: isDark,
                  selectedAyah: selectedAyah,
                  selectedWord: selectedWord,
                  onAyahTap: onAyahTap,
                  onWordTap: onWordTap,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _QpcLineView extends StatelessWidget {
  const _QpcLineView({
    required this.line,
    required this.fontFamily,
    required this.lineHeight,
    required this.isDark,
    required this.selectedAyah,
    required this.selectedWord,
    required this.onAyahTap,
    required this.onWordTap,
  });

  final QpcMushafLine? line;
  final String fontFamily;
  final double lineHeight;
  final bool isDark;
  final QpcAyahKey? selectedAyah;
  final QpcWordKey? selectedWord;
  final Future<void> Function(QpcAyahKey ayahKey) onAyahTap;
  final Future<void> Function(QpcWord word) onWordTap;

  @override
  Widget build(BuildContext context) {
    final QpcMushafLine? currentLine = line;

    if (currentLine == null) {
      return const SizedBox.expand();
    }

    if (currentLine.lineType == 'surah_name') {
      return _SurahHeaderLine(
        surahNumber: currentLine.surahNumber,
        lineHeight: lineHeight,
        isDark: isDark,
      );
    }

    if (currentLine.lineType == 'basmallah' && currentLine.words.isEmpty) {
      return _BasmallahLine(
        lineHeight: lineHeight,
        isDark: isDark,
      );
    }

    if (currentLine.words.isEmpty) {
      return const SizedBox.expand();
    }

    final double fontSize = _fontSizeForLine(
      line: currentLine,
      lineHeight: lineHeight,
    );

    final TextStyle baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.0,
      color: isDark ? Colors.white : Colors.black,
    );

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: baseStyle,
              children: currentLine.words.map((word) {
                final bool ayahSelected =
                    selectedAyah?.surah == word.surah &&
                        selectedAyah?.ayah == word.ayah;

                final bool wordSelected =
                    selectedWord?.surah == word.surah &&
                        selectedWord?.ayah == word.ayah &&
                        selectedWord?.word == word.word;

                TextStyle style = baseStyle;

                if (ayahSelected) {
                  style = style.copyWith(
                    color: isDark
                        ? const Color(0xffB9F4DE)
                        : const Color(0xff005349),
                    backgroundColor: isDark
                        ? const Color(0xff21C58E).withOpacity(0.22)
                        : const Color(0xff21C58E).withOpacity(0.14),
                  );
                }

                if (wordSelected) {
                  style = style.copyWith(
                    color: Colors.white,
                    backgroundColor: isDark
                        ? const Color(0xff0B8F73).withOpacity(0.95)
                        : const Color(0xff005349).withOpacity(0.86),
                  );
                }

                return TextSpan(
                  text: word.text,
                  style: style,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      onWordTap(word);
                    },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  double _fontSizeForLine({
    required QpcMushafLine line,
    required double lineHeight,
  }) {
    // مهم: مصحف QPC معمول بصفحات/خطوط ثابتة.
    // تكبير السطر حسب عدد الكلمات كان سبب إن آيات قصيرة تظهر كبيرة جدًا.
    return (lineHeight * 0.78).clamp(16.0, 30.0).toDouble();
  }
}

class _SurahHeaderLine extends StatelessWidget {
  const _SurahHeaderLine({
    required this.surahNumber,
    required this.lineHeight,
    required this.isDark,
  });

  final int? surahNumber;
  final double lineHeight;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (surahNumber == null || surahNumber! < 1 || surahNumber! > 114) {
      return const SizedBox.expand();
    }

    // surah-name-v2.ttf هو خط أسماء السور الأسود الموجود ضمن ملفاتك.
    // نستخدمه هنا بدل QCF_SurahHeader_COLOR لأن الأخير Color Font ويظهر ملونًا.
    final String surahNameGlyph = String.fromCharCode(0xE000 + surahNumber!);
    final double fontSize = (lineHeight * 1.55).clamp(32.0, 72.0).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(
            color: isDark ? Colors.white70 : Colors.black87,
            width: 1.15,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              surahNameGlyph,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: QpcCommonFontLoader.surahNameFamily,
                fontSize: fontSize,
                height: 1.0,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BasmallahLine extends StatelessWidget {
  const _BasmallahLine({
    required this.lineHeight,
    required this.isDark,
  });

  final double lineHeight;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final double fontSize = (lineHeight * 0.92).clamp(20.0, 40.0).toDouble();

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          String.fromCharCode(0xFDFD),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: QpcCommonFontLoader.quranCommonFamily,
            fontSize: fontSize,
            height: 1.0,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class QpcPageData {
  const QpcPageData({
    required this.pageNumber,
    required this.lines,
  });

  final int pageNumber;
  final List<QpcMushafLine> lines;

  QpcMushafLine? lineByNumber(int number) {
    for (final QpcMushafLine line in lines) {
      if (line.lineNumber == number) {
        return line;
      }
    }

    return null;
  }
}

class QpcMushafLine {
  const QpcMushafLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.firstWordId,
    required this.lastWordId,
    required this.surahNumber,
    required this.words,
  });

  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;
  final List<QpcWord> words;

  List<QpcAyahSpanData> toAyahSpans() {
    final List<QpcAyahSpanData> result = <QpcAyahSpanData>[];

    if (words.isEmpty) {
      return result;
    }

    final StringBuffer buffer = StringBuffer();
    QpcAyahKey? currentKey;

    void flush() {
      if (currentKey == null || buffer.isEmpty) {
        return;
      }

      result.add(
        QpcAyahSpanData(
          ayahKey: currentKey!,
          text: buffer.toString(),
        ),
      );

      buffer.clear();
    }

    for (final QpcWord word in words) {
      final QpcAyahKey wordKey = QpcAyahKey(
        surah: word.surah,
        ayah: word.ayah,
      );

      if (currentKey == null) {
        currentKey = wordKey;
      } else if (currentKey!.surah != wordKey.surah ||
          currentKey!.ayah != wordKey.ayah) {
        flush();
        currentKey = wordKey;
      }

      buffer.write(word.text);
    }

    flush();

    return result;
  }
}

class QpcWord {
  const QpcWord({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.location,
    required this.text,
  });

  final int id;
  final int surah;
  final int ayah;
  final int word;
  final String location;
  final String text;
}

class QpcWordKey {
  const QpcWordKey({
    required this.surah,
    required this.ayah,
    required this.word,
  });

  final int surah;
  final int ayah;
  final int word;
}

class QpcAyahKey {
  const QpcAyahKey({
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;
}

class QpcAyahSpanData {
  const QpcAyahSpanData({
    required this.ayahKey,
    required this.text,
  });

  final QpcAyahKey ayahKey;
  final String text;
}

class QpcMushafRepository {
  QpcMushafRepository._();

  static final QpcMushafRepository instance = QpcMushafRepository._();

  static const String _wordsDbAsset = 'assets/quran/qpc-v2.db';
  static const String _layoutDbAsset = 'assets/quran/qpc-v2-15-lines.db';

  Database? _wordsDb;
  Database? _layoutDb;

  Future<QpcPageData> loadPage(int pageNumber) async {
    final Database wordsDb = await _openWordsDb();
    final Database layoutDb = await _openLayoutDb();

    final List<Map<String, Object?>> lineRows = await layoutDb.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: <Object?>[pageNumber],
      orderBy: 'line_number ASC',
    );

    final List<QpcMushafLine> lines = <QpcMushafLine>[];

    for (final Map<String, Object?> row in lineRows) {
      final int lineNumber = _asInt(row['line_number']) ?? 0;
      final String lineType = row['line_type']?.toString() ?? '';
      final bool isCentered = (_asInt(row['is_centered']) ?? 0) == 1;
      final int? firstWordId = _asInt(row['first_word_id']);
      final int? lastWordId = _asInt(row['last_word_id']);
      final int? surahNumber = _asInt(row['surah_number']);

      final List<QpcWord> words = <QpcWord>[];

      if (firstWordId != null && lastWordId != null) {
        final List<Map<String, Object?>> wordRows = await wordsDb.query(
          'words',
          where: 'id >= ? AND id <= ?',
          whereArgs: <Object?>[firstWordId, lastWordId],
          orderBy: 'id ASC',
        );

        for (final Map<String, Object?> wordRow in wordRows) {
          words.add(
            QpcWord(
              id: _asInt(wordRow['id']) ?? 0,
              surah: _asInt(wordRow['surah']) ?? 0,
              ayah: _asInt(wordRow['ayah']) ?? 0,
              word: _asInt(wordRow['word']) ?? 0,
              location: wordRow['location']?.toString() ?? '',
              text: wordRow['text']?.toString() ?? '',
            ),
          );
        }
      }

      lines.add(
        QpcMushafLine(
          pageNumber: pageNumber,
          lineNumber: lineNumber,
          lineType: lineType,
          isCentered: isCentered,
          firstWordId: firstWordId,
          lastWordId: lastWordId,
          surahNumber: surahNumber,
          words: words,
        ),
      );
    }

    return QpcPageData(
      pageNumber: pageNumber,
      lines: lines,
    );
  }

  Future<Database> _openWordsDb() async {
    if (_wordsDb != null) {
      return _wordsDb!;
    }

    final String dbPath = await _copyAssetDatabaseIfNeeded(
      assetPath: _wordsDbAsset,
      fileName: 'qpc-v2.db',
    );

    _wordsDb = await openDatabase(
      dbPath,
      readOnly: true,
      singleInstance: true,
    );

    return _wordsDb!;
  }

  Future<Database> _openLayoutDb() async {
    if (_layoutDb != null) {
      return _layoutDb!;
    }

    final String dbPath = await _copyAssetDatabaseIfNeeded(
      assetPath: _layoutDbAsset,
      fileName: 'qpc-v2-15-lines.db',
    );

    _layoutDb = await openDatabase(
      dbPath,
      readOnly: true,
      singleInstance: true,
    );

    return _layoutDb!;
  }

  Future<String> _copyAssetDatabaseIfNeeded({
    required String assetPath,
    required String fileName,
  }) async {
    final Directory directory = await getApplicationSupportDirectory();
    final String dbDirectoryPath = path.join(directory.path, 'qpc_databases_v2');

    await Directory(dbDirectoryPath).create(recursive: true);

    final String targetPath = path.join(dbDirectoryPath, fileName);
    final File targetFile = File(targetPath);

    if (await targetFile.exists()) {
      return targetPath;
    }

    final ByteData data = await rootBundle.load(assetPath);

    await targetFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );

    return targetPath;
  }
}



class QpcCommonFontLoader {
  QpcCommonFontLoader._();

  static final QpcCommonFontLoader instance = QpcCommonFontLoader._();

  static const String surahHeaderFamily = 'QCF_SurahHeader_COLOR';
  static const String surahNameFamily = 'surah-name-v2';
  static const String quranCommonFamily = 'quran-common';

  Future<void>? _loadingTask;
  bool _loaded = false;

  Future<void> ensureLoaded() {
    if (_loaded) {
      return Future<void>.value();
    }

    final Future<void>? running = _loadingTask;
    if (running != null) {
      return running;
    }

    final Future<void> task = _load();
    _loadingTask = task;
    return task;
  }

  Future<void> _load() async {
    final FontLoader surahHeaderLoader = FontLoader(surahHeaderFamily)
      ..addFont(
        rootBundle.load('assets/fonts/QCF_SurahHeader_COLOR-Regular.ttf'),
      );

    final FontLoader surahNameLoader = FontLoader(surahNameFamily)
      ..addFont(
        rootBundle.load('assets/fonts/surah-name-v2.ttf'),
      );

    final FontLoader quranCommonLoader = FontLoader(quranCommonFamily)
      ..addFont(
        rootBundle.load('assets/fonts/quran-common.ttf'),
      );

    await Future.wait(<Future<void>>[
      surahHeaderLoader.load(),
      surahNameLoader.load(),
      quranCommonLoader.load(),
    ]);

    _loaded = true;
  }
}

class QpcPageFontLoader {
  QpcPageFontLoader._();

  static final QpcPageFontLoader instance = QpcPageFontLoader._();

  final Set<int> _loadedPages = <int>{};
  final Map<int, Future<void>> _loadingPages = <int, Future<void>>{};

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

    final Future<void>? running = _loadingPages[pageNumber];

    if (running != null) {
      return running;
    }

    final Future<void> task = _load(pageNumber);
    _loadingPages[pageNumber] = task;

    return task;
  }

  Future<void> _load(int pageNumber) async {
    try {
      final String family = familyForPage(pageNumber);
      final FontLoader loader = FontLoader(family);

      loader.addFont(
        rootBundle.load('assets/fonts/qpc/p$pageNumber.ttf'),
      );

      await loader.load();
      _loadedPages.add(pageNumber);
    } finally {
      _loadingPages.remove(pageNumber);
    }
  }

  void preloadAround(int pageNumber, {int radius = 6}) {
    for (int page = pageNumber - radius; page <= pageNumber + radius; page++) {
      if (page >= 1 && page <= 604) {
        ensureLoaded(page);
      }
    }
  }
}

class _StaticMushafHeader extends StatelessWidget {
  const _StaticMushafHeader({
    required this.suraName,
    required this.juzNumber,
    required this.isDark,
  });

  final String suraName;
  final int juzNumber;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isDark
        ? const Color(0xff071817)
        : const Color(0xffFFFDF6);
    final Color textColor = isDark ? Colors.white70 : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      height: 22.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              suraName,
              textAlign: TextAlign.left,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.2.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'الجزء $juzNumber',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 7.8.sp,
                fontWeight: FontWeight.w500,
                color: subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslamicPageNumberBadge extends StatelessWidget {
  const _IslamicPageNumberBadge({
    required this.pageNumber,
    required this.isDark,
  });

  final int pageNumber;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isDark
        ? const Color(0xffA8D7D0)
        : const Color(0xff224368);
    final Color backgroundColor = isDark
        ? const Color(0xff102623)
        : const Color(0xffFFFDF6);
    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff224368);

    return Container(
      width: 35.w,
      height: 19.h,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.88),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: borderColor.withOpacity(0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.07),
            blurRadius: 6,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4.w,
            child: _SmallDecorationDot(color: borderColor),
          ),
          Positioned(
            right: 4.w,
            child: _SmallDecorationDot(color: borderColor),
          ),
          Text(
            '$pageNumber',
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallDecorationDot extends StatelessWidget {
  const _SmallDecorationDot({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.w,
      height: 4.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.65),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MushafPageControls extends StatelessWidget {
  const _MushafPageControls({
    required this.selectedPageNumber,
    required this.currentSuraName,
    required this.currentJuzNumber,
    required this.isDark,
    required this.onJumpToPage,
  });

  final int selectedPageNumber;
  final String currentSuraName;
  final int currentJuzNumber;
  final bool isDark;
  final ValueChanged<int> onJumpToPage;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
    isDark ? const Color(0xff005349) : const Color(0xff224368);

    final int safePageNumber = selectedPageNumber.clamp(1, 604);

    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.82),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _PageControlIcon(
            icon: Icons.keyboard_double_arrow_right_rounded,
            onTap: () {
              onJumpToPage((safePageNumber + 10).clamp(1, 604));
            },
          ),
          _PageControlIcon(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              onJumpToPage((safePageNumber + 1).clamp(1, 604));
            },
          ),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.h,
                  showValueIndicator: ShowValueIndicator.onlyForDiscrete,
                  valueIndicatorTextStyle: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 5.5.r,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  min: 1,
                  max: 604,
                  divisions: 603,
                  value: safePageNumber.toDouble(),
                  label:
                  'سورة $currentSuraName | ص $safePageNumber | جزء $currentJuzNumber',
                  onChanged: (value) {
                    onJumpToPage(value.round());
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            '$safePageNumber',
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 5.w),
          _PageControlIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              onJumpToPage((safePageNumber - 1).clamp(1, 604));
            },
          ),
          _PageControlIcon(
            icon: Icons.keyboard_double_arrow_left_rounded,
            onTap: () {
              onJumpToPage((safePageNumber - 10).clamp(1, 604));
            },
          ),
        ],
      ),
    );
  }
}

class _PageControlIcon extends StatelessWidget {
  const _PageControlIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () {
        AppHaptics.tap(context);
        onTap();
      },
      child: SizedBox(
        width: 24.w,
        height: 28.h,
        child: Icon(
          icon,
          size: 17.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _QpcAudioMiniBar extends StatelessWidget {
  const _QpcAudioMiniBar({
    required this.ayahKey,
    required this.isLoading,
    required this.onStop,
  });

  final QpcAyahKey? ayahKey;
  final bool isLoading;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xff005349);

    final String title = ayahKey == null
        ? 'جاري تجهيز الصوت...'
        : 'تشغيل الآية ${ayahKey!.surah}:${ayahKey!.ayah}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 19.sp,
              ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: onStop,
              child: Padding(
                padding: EdgeInsets.all(5.w),
                child: Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingMushafPage extends StatelessWidget {
  const _MissingMushafPage({
    required this.pageNumber,
    required this.isDark,
    this.message,
  });

  final int pageNumber;
  final bool isDark;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(
          message == null
              ? 'صفحة $pageNumber غير موجودة'
              : 'تعذر تحميل صفحة $pageNumber\n$message',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 12.sp,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

int? _asInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}
