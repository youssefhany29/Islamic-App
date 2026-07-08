import 'dart:math' as math;

import 'package:islamic_app/features/memorization/data/services/quran_range_label_resolver.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import '../models/memorization_test_question_model.dart';

typedef AyahTextResolver = String Function(int globalAyahIndex);

class MemorizationTestQuestionEngine {
  const MemorizationTestQuestionEngine();

  List<MemorizationTestQuestionModel> buildQuestions({
    required MemorizationTodayTaskModel task,
    AyahTextResolver? ayahTextResolver,
    int maxQuestions = 20,
    int? attemptNumber,
    Set<String> recentQuestionFingerprints = const <String>{},
  }) {
    if (!task.hasValidRange) return const [];

    final fullTextResolver = ayahTextResolver ?? _defaultAyahLabel;
    String resolver(int index) => _questionText(fullTextResolver(index));
    final start = task.startGlobalAyahIndex
        .clamp(0, QuranReaderHelpers.totalAyahs - 1)
        .toInt();
    final end = task.endGlobalAyahIndex
        .clamp(start, QuranReaderHelpers.totalAyahs - 1)
        .toInt();

    final ayahIndexes = List<int>.generate(
      end - start + 1,
      (index) => start + index,
    );

    if (ayahIndexes.isEmpty) return const [];

    final limit = _questionLimit(task: task, requestedLimit: maxQuestions);
    final bank = <MemorizationTestQuestionModel>[];
    final seed = _stableSeed(
      '${task.planId}|${task.id}|'
      '${task.effectiveScheduledDate.toIso8601String()}|'
      '${task.testTriggerCode.isEmpty ? task.testKindCode : task.testTriggerCode}|'
      '${attemptNumber ?? task.attemptNumber}|${task.planVersion}',
    );
    final random = math.Random(seed);

    for (int i = 0; i < ayahIndexes.length; i++) {
      final current = ayahIndexes[i];
      final previous = i > 0 ? ayahIndexes[i - 1] : null;
      final next = i + 1 < ayahIndexes.length ? ayahIndexes[i + 1] : null;

      bank.addAll([
        if (_canSplitAyah(resolver(current)))
          _completeAyahQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (_canSplitAyah(resolver(current)))
          _chooseCompletionQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (_canBuildWordChoice(resolver(current)))
          _chooseWordQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (next != null)
          _nextAyahQuestion(
            current: current,
            next: next,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (previous != null)
          _previousAyahQuestion(
            current: current,
            previous: previous,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (_canBuildBoundaryQuestion(resolver(current)))
          _ayahStartQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (ayahIndexes.length > 1)
          _chooseAyahQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (_canBuildBoundaryQuestion(resolver(current)))
          _ayahEndingQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        if (_canBuildWordOrder(resolver(current)))
          _orderWordsQuestion(index: current, resolver: resolver),
        if (i % 4 == 0)
          _similarAyahQuestion(
            index: current,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
      ]);

      if (i % 5 == 0) {
        bank.add(_hiddenAyahQuestion(index: current, resolver: resolver));
      }

      if (i % 6 == 0) {
        bank.add(_noTextQuestion(index: current, resolver: resolver));
      }
    }

    bank.addAll(
      _buildOrderAyahQuestions(
        indexes: ayahIndexes,
        resolver: resolver,
        random: random,
      ),
    );

    if (ayahIndexes.length >= 6) {
      for (final anchor in _sliceAnchors(ayahIndexes)) {
        bank.add(
          _fullPageQuestion(
            anchor: anchor,
            allIndexes: ayahIndexes,
            resolver: resolver,
          ),
        );
      }
    }

    bank.addAll(
      _buildHiddenMushafQuestions(indexes: ayahIndexes, resolver: resolver),
    );

    final validBank = bank
        .map((question) => _withFeedback(question, fullTextResolver))
        .where(_isValidQuestion)
        .toList(growable: false);
    var prioritized = _prioritizeQuestionBank(
      bank: validBank,
      task: task,
      ayahsCount: ayahIndexes.length,
    );
    if (task.allowedQuestionTypeCodes.isNotEmpty) {
      final allowed = task.allowedQuestionTypeCodes.toSet();
      prioritized = prioritized
          .where((question) => allowed.contains(question.type.code))
          .toList(growable: false);
    }

    final unique = _deduplicate(prioritized);
    final fresh = unique
        .where(
          (question) => !recentQuestionFingerprints.contains(
            question.questionFingerprint,
          ),
        )
        .toList(growable: false);
    final candidates = fresh.length >= limit
        ? fresh
        : <MemorizationTestQuestionModel>[
            ...fresh,
            ...unique.where(
              (question) => recentQuestionFingerprints.contains(
                question.questionFingerprint,
              ),
            ),
          ];

    return _selectMixedQuestions(
      questions: candidates,
      limit: limit,
      rangeStart: start,
      rangeEnd: end,
      random: random,
    );
  }

  int _questionLimit({
    required MemorizationTodayTaskModel task,
    required int requestedLimit,
  }) {
    return requestedLimit.clamp(1, 30).toInt();
  }

  List<MemorizationTestQuestionModel> _prioritizeQuestionBank({
    required List<MemorizationTestQuestionModel> bank,
    required MemorizationTodayTaskModel task,
    required int ayahsCount,
  }) {
    final preferredTypes = <MemorizationQuestionType>[
      if (task.type == 'weakReview') ...[
        MemorizationQuestionType.previousAyah,
        MemorizationQuestionType.ayahEndings,
        MemorizationQuestionType.similarAyahs,
      ],
      if (task.type == 'selfTest') ...[
        MemorizationQuestionType.chooseAyahCompletion,
        MemorizationQuestionType.chooseWord,
        MemorizationQuestionType.nextAyah,
        MemorizationQuestionType.noTextRecitation,
      ],
      if (ayahsCount <= 8) ...[
        MemorizationQuestionType.orderWords,
        MemorizationQuestionType.chooseAyahCompletion,
      ],
      MemorizationQuestionType.completeAyah,
      MemorizationQuestionType.chooseAyah,
      MemorizationQuestionType.ayahStarts,
      MemorizationQuestionType.ayahEndings,
      MemorizationQuestionType.ayahPosition,
      MemorizationQuestionType.ayahStarts,
      MemorizationQuestionType.previousAyah,
      MemorizationQuestionType.orderAyahs,
      MemorizationQuestionType.orderWords,
      MemorizationQuestionType.hiddenAyahs,
      MemorizationQuestionType.noTextRecitation,
      MemorizationQuestionType.hiddenMushafRecitation,
      MemorizationQuestionType.similarAyahs,
      MemorizationQuestionType.fullPageRecitation,
    ];

    final scored =
        bank.map((question) {
          final preferredIndex = preferredTypes.indexOf(question.type);
          final typeScore = preferredIndex < 0 ? 999 : preferredIndex;
          return _ScoredQuestion(question: question, score: typeScore);
        }).toList()..sort((a, b) {
          final scoreCompare = a.score.compareTo(b.score);
          if (scoreCompare != 0) return scoreCompare;
          return 0;
        });

    return scored.map((item) => item.question).toList(growable: false);
  }

  List<MemorizationTestQuestionModel> _selectMixedQuestions({
    required List<MemorizationTestQuestionModel> questions,
    required int limit,
    required int rangeStart,
    required int rangeEnd,
    required math.Random random,
  }) {
    if (questions.length <= limit) {
      final result = List<MemorizationTestQuestionModel>.from(questions)
        ..shuffle(random);
      return result;
    }

    final byType =
        <MemorizationQuestionType, List<MemorizationTestQuestionModel>>{};
    for (final question in questions) {
      byType.putIfAbsent(question.type, () => []).add(question);
    }
    for (final values in byType.values) {
      values.shuffle(random);
    }

    final types = byType.keys.toList()..shuffle(random);
    final selected = <MemorizationTestQuestionModel>[];
    final selectedIds = <String>{};
    int slice = 0;

    bool tryAdd(MemorizationTestQuestionModel question) {
      if (selectedIds.contains(question.questionFingerprint)) return false;
      if (!_respectsLocalBlockRule(selected, question, rangeStart, rangeEnd)) {
        return false;
      }
      selected.add(question);
      selectedIds.add(question.questionFingerprint);
      return true;
    }

    for (final type in types) {
      if (selected.length >= limit) break;
      final candidates = byType[type]!;
      final preferredSlice = slice % 3;
      final preferred = candidates.where((question) {
        return _sliceFor(question.startGlobalAyahIndex, rangeStart, rangeEnd) ==
            preferredSlice;
      });
      final candidate = preferred.isNotEmpty
          ? preferred.first
          : candidates.first;
      if (tryAdd(candidate)) slice++;
    }

    final remaining =
        questions
            .where(
              (question) => !selectedIds.contains(question.questionFingerprint),
            )
            .toList()
          ..shuffle(random);

    for (final question in remaining) {
      if (selected.length >= limit) break;
      tryAdd(question);
    }

    if (selected.length < limit) {
      for (final question in remaining) {
        if (selected.length >= limit) break;
        if (selectedIds.add(question.questionFingerprint)) {
          selected.add(question);
        }
      }
    }

    return selected;
  }

  bool _respectsLocalBlockRule(
    List<MemorizationTestQuestionModel> selected,
    MemorizationTestQuestionModel candidate,
    int rangeStart,
    int rangeEnd,
  ) {
    if (selected.length < 2) return true;
    final candidateBlock = _localBlock(
      candidate.startGlobalAyahIndex,
      rangeStart,
      rangeEnd,
    );
    final lastTwo = selected.skip(selected.length - 2);
    return !lastTwo.every(
      (item) =>
          _localBlock(item.startGlobalAyahIndex, rangeStart, rangeEnd) ==
          candidateBlock,
    );
  }

  int _localBlock(int index, int start, int end) {
    final length = math.max(1, end - start + 1);
    final blockSize = math.max(1, (length / 6).ceil());
    return ((index - start) / blockSize).floor();
  }

  int _sliceFor(int index, int start, int end) {
    final length = math.max(1, end - start + 1);
    return (((index - start) * 3) / length).floor().clamp(0, 2).toInt();
  }

  List<MemorizationTestQuestionModel> _deduplicate(
    List<MemorizationTestQuestionModel> questions,
  ) {
    final seen = <String>{};
    final result = <MemorizationTestQuestionModel>[];

    for (final question in questions) {
      final key = question.questionFingerprint;
      if (seen.add(key)) result.add(question);
    }

    return result;
  }

  MemorizationTestQuestionModel _completeAyahQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final parts = _splitAyah(resolver(index));

    return MemorizationTestQuestionModel(
      id: 'complete_$index',
      type: MemorizationQuestionType.completeAyah,
      title: MemorizationQuestionType.completeAyah.title,
      prompt: 'أكمل الآية:\n${parts.start} ...',
      hint: 'اختر التكملة فقط دون إعادة بداية الآية.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: _completionOptions(
        correctIndex: index,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: index + 11,
      ),
      correctAnswerText: parts.end,
      promptAyahText: parts.start,
    );
  }

  MemorizationTestQuestionModel _chooseCompletionQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final parts = _splitAyah(resolver(index));

    return MemorizationTestQuestionModel(
      id: 'choose_completion_$index',
      type: MemorizationQuestionType.chooseAyahCompletion,
      title: MemorizationQuestionType.chooseAyahCompletion.title,
      prompt: 'اختر التكملة الصحيحة بعد:\n${parts.start} ...',
      hint: 'كل الإجابات اختيارات فقط، بدون كتابة.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: _completionOptions(
        correctIndex: index,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: index + 17,
      ),
      correctAnswerText: parts.end,
      promptAyahText: parts.start,
    );
  }

  MemorizationTestQuestionModel _nextAyahQuestion({
    required int current,
    required int next,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    return MemorizationTestQuestionModel(
      id: 'next_$current',
      type: MemorizationQuestionType.nextAyah,
      title: MemorizationQuestionType.nextAyah.title,
      prompt: 'ما الآية التي تأتي بعد:\n${resolver(current)}',
      hint: 'اختبار ربط الآيات ببعضها.',
      startGlobalAyahIndex: current,
      endGlobalAyahIndex: next,
      options: _buildChoiceOptions(
        correctIndex: next,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: current + 29,
      ),
      correctAnswerText: resolver(next),
      promptAyahText: resolver(current),
    );
  }

  MemorizationTestQuestionModel _chooseWordQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final words = _words(resolver(index));
    final missingIndex = (words.length / 2).floor();
    final correctWord = words[missingIndex];
    final visibleWords = List<String>.from(words);
    visibleWords[missingIndex] = '_____';
    final candidates = <String>{correctWord};

    for (final otherIndex in allIndexes) {
      for (final word in _words(resolver(otherIndex))) {
        if (word != correctWord && word.length >= 2) candidates.add(word);
        if (candidates.length >= 8) break;
      }
      if (candidates.length >= 8) break;
    }

    final random = math.Random(index + 101);
    final distractors = candidates.where((word) => word != correctWord).toList()
      ..shuffle(random);
    final selected = <String>[correctWord, ...distractors.take(3)]
      ..shuffle(random);

    return MemorizationTestQuestionModel(
      id: 'choose_word_$index',
      type: MemorizationQuestionType.chooseWord,
      title: MemorizationQuestionType.chooseWord.title,
      prompt: 'اختر الكلمة الناقصة:\n${visibleWords.join(' ')}',
      hint: 'اختر الكلمة التي تكمل النص كما ورد.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: [
        for (int i = 0; i < selected.length; i++)
          MemorizationQuestionOption(
            id: 'word_choice_${index}_$i',
            text: selected[i],
            isCorrect: selected[i] == correctWord,
          ),
      ],
      correctAnswerText: correctWord,
      promptAyahText: visibleWords.join(' '),
    );
  }

  MemorizationTestQuestionModel _chooseAyahQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final localIndex = allIndexes.indexOf(index);
    final hasPrevious = localIndex > 0;
    final referenceIndex = hasPrevious
        ? allIndexes[localIndex - 1]
        : localIndex + 1 < allIndexes.length
        ? allIndexes[localIndex + 1]
        : index;
    final relation = hasPrevious ? 'بعد' : 'قبل';

    return MemorizationTestQuestionModel(
      id: 'choose_ayah_$index',
      type: MemorizationQuestionType.chooseAyah,
      title: MemorizationQuestionType.chooseAyah.title,
      prompt:
          'اختر الآية الصحيحة التي تأتي $relation هذا الموضع:\n'
          '${resolver(referenceIndex)}',
      hint: 'الاختيارات كلها من نطاق الحفظ نفسه.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: _buildChoiceOptions(
        correctIndex: index,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: index + 107,
      ),
      correctAnswerText: resolver(index),
      promptAyahText: resolver(referenceIndex),
    );
  }

  MemorizationTestQuestionModel _previousAyahQuestion({
    required int current,
    required int previous,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    return MemorizationTestQuestionModel(
      id: 'previous_$current',
      type: MemorizationQuestionType.previousAyah,
      title: MemorizationQuestionType.previousAyah.title,
      prompt: 'ما الآية التي تأتي قبل:\n${resolver(current)}',
      hint: 'مهم جدًا لتثبيت الانتقال العكسي وعدم الخلط.',
      startGlobalAyahIndex: previous,
      endGlobalAyahIndex: current,
      options: _buildChoiceOptions(
        correctIndex: previous,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: current + 37,
      ),
      correctAnswerText: resolver(previous),
      promptAyahText: resolver(current),
    );
  }

  MemorizationTestQuestionModel _orderAyahsQuestion({
    required List<int> indexes,
    required AyahTextResolver resolver,
  }) {
    final correct = indexes.map(resolver).join('\nثم\n');
    final options = _orderedItemOptions(
      correctIndexes: indexes,
      resolver: resolver,
      seed: indexes.first + 41,
      idPrefix: 'order_ayahs',
    );

    return MemorizationTestQuestionModel(
      id: 'order_${indexes.first}_${indexes.last}',
      type: MemorizationQuestionType.orderAyahs,
      title: MemorizationQuestionType.orderAyahs.title,
      prompt: 'اختر الترتيب الصحيح لهذه الآيات.',
      hint: 'الآيات من مقطع واحد متتالٍ داخل سورة واحدة.',
      startGlobalAyahIndex: indexes.first,
      endGlobalAyahIndex: indexes.last,
      options: options,
      correctAnswerText: correct,
    );
  }

  List<MemorizationTestQuestionModel> _buildOrderAyahQuestions({
    required List<int> indexes,
    required AyahTextResolver resolver,
    required math.Random random,
  }) {
    if (indexes.length < 3) return const [];
    final candidates = _contiguousSameSurahSegments(indexes);
    if (candidates.isEmpty) return const [];

    candidates.shuffle(random);
    final selected = <List<int>>[];
    final usedStarts = <int>{};
    for (final candidate in candidates) {
      if (!usedStarts.add(candidate.first)) continue;
      selected.add(candidate);
      if (selected.length >= 3) break;
    }

    return selected
        .map((group) => _orderAyahsQuestion(indexes: group, resolver: resolver))
        .toList(growable: false);
  }

  List<List<int>> _contiguousSameSurahSegments(List<int> indexes) {
    final sorted = indexes.toSet().toList()..sort();
    final bySurah = <int, List<int>>{};
    for (final index in sorted) {
      final position = QuranReaderHelpers.getPositionFromGlobalIndex(index);
      bySurah.putIfAbsent(position.suraIndex, () => <int>[]).add(index);
    }

    final segments = <List<int>>[];
    for (final surahIndexes in bySurah.values) {
      if (surahIndexes.length < 3) continue;
      for (int start = 0; start <= surahIndexes.length - 3; start++) {
        final maxLength = math.min(6, surahIndexes.length - start);
        for (int length = maxLength; length >= 3; length--) {
          final candidate = surahIndexes.sublist(start, start + length);
          var contiguous = true;
          for (int i = 1; i < candidate.length; i++) {
            if (candidate[i] != candidate[i - 1] + 1) {
              contiguous = false;
              break;
            }
          }
          if (contiguous) {
            segments.add(candidate);
            break;
          }
        }
      }
    }
    return segments;
  }

  List<int> _sliceAnchors(List<int> indexes) {
    if (indexes.isEmpty) return const [];
    return <int>[
      indexes[(indexes.length * 0.16)
          .floor()
          .clamp(0, indexes.length - 1)
          .toInt()],
      indexes[(indexes.length * 0.50)
          .floor()
          .clamp(0, indexes.length - 1)
          .toInt()],
      indexes[(indexes.length * 0.84)
          .floor()
          .clamp(0, indexes.length - 1)
          .toInt()],
    ].toSet().toList();
  }

  MemorizationTestQuestionModel _orderWordsQuestion({
    required int index,
    required AyahTextResolver resolver,
  }) {
    final words = _words(resolver(index)).take(8).toList(growable: false);
    final correct = words.join(' ');
    final random = math.Random(index + 53);
    final options = List<MemorizationQuestionOption>.generate(words.length, (
      i,
    ) {
      return MemorizationQuestionOption(
        id: 'word_${index}_$i',
        text: words[i],
        isCorrect: false,
        correctOrder: i,
      );
    })..shuffle(random);

    return MemorizationTestQuestionModel(
      id: 'order_words_$index',
      type: MemorizationQuestionType.orderWords,
      title: MemorizationQuestionType.orderWords.title,
      prompt: 'اختر ترتيب الكلمات الصحيح.',
      hint: 'أعد ترتيب الكلمات كما وردت في الآية.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: options,
      correctAnswerText: correct,
    );
  }

  MemorizationTestQuestionModel _ayahStartQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final ending = _lastWords(resolver(index), 4);
    final correctStart = _firstWords(resolver(index), 4);

    return MemorizationTestQuestionModel(
      id: 'start_$index',
      type: MemorizationQuestionType.ayahStarts,
      title: MemorizationQuestionType.ayahStarts.title,
      prompt: 'اختر بداية الآية التي تنتهي بـ:\n... $ending',
      hint: 'اختر البداية الصحيحة دون عرضها داخل السؤال.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: _buildTextSegmentOptions(
        correctIndex: index,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: index + 61,
        segmentResolver: (text) => _firstWords(text, 4),
      ),
      correctAnswerText: correctStart,
      promptAyahText: ending,
    );
  }

  MemorizationTestQuestionModel _ayahEndingQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final beginning = _firstWords(resolver(index), 4);
    final correctEnding = _lastWords(resolver(index), 4);

    return MemorizationTestQuestionModel(
      id: 'ending_$index',
      type: MemorizationQuestionType.ayahEndings,
      title: MemorizationQuestionType.ayahEndings.title,
      prompt: 'اختر خاتمة الآية التي تبدأ بـ:\n$beginning ...',
      hint: 'اختر الخاتمة الصحيحة دون عرضها داخل السؤال.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: _buildTextSegmentOptions(
        correctIndex: index,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: index + 67,
        segmentResolver: (text) => _lastWords(text, 4),
      ),
      correctAnswerText: correctEnding,
      promptAyahText: beginning,
    );
  }

  MemorizationTestQuestionModel _similarAyahQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final clue = _firstWords(resolver(index), 4);

    return MemorizationTestQuestionModel(
      id: 'similar_$index',
      type: MemorizationQuestionType.similarAyahs,
      title: MemorizationQuestionType.similarAyahs.title,
      prompt: 'اختر التكملة التي توافق هذه البداية:\n$clue ...',
      hint: 'الاختيارات تعرض التكملة فقط.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: _buildTextSegmentOptions(
        correctIndex: index,
        allIndexes: allIndexes,
        resolver: resolver,
        seed: index + 79,
        segmentResolver: (text) => _suffixAfterWords(text, 4),
      ),
      correctAnswerText: _suffixAfterWords(resolver(index), 4),
      promptAyahText: clue,
    );
  }

  MemorizationTestQuestionModel _ayahPositionQuestion({
    required int index,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final random = math.Random(index + 113);
    final selected = _candidateIndexes(index, allIndexes, random);
    final options =
        selected
            .map(
              (candidate) => MemorizationQuestionOption(
                id: 'position_$candidate',
                text: _positionLabel(candidate),
                isCorrect: candidate == index,
              ),
            )
            .toList()
          ..shuffle(random);

    return MemorizationTestQuestionModel(
      id: 'ayah_position_$index',
      type: MemorizationQuestionType.ayahPosition,
      title: MemorizationQuestionType.ayahPosition.title,
      prompt: 'أين موضع هذه الآية؟\n${resolver(index)}',
      hint: 'اختر السورة ورقم الآية الصحيحين.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: options,
      correctAnswerText: _positionLabel(index),
    );
  }

  MemorizationTestQuestionModel _hiddenAyahQuestion({
    required int index,
    required AyahTextResolver resolver,
  }) {
    final preview = _hideEveryOtherWord(resolver(index));

    return MemorizationTestQuestionModel(
      id: 'hidden_$index',
      type: MemorizationQuestionType.hiddenAyahs,
      title: MemorizationQuestionType.hiddenAyahs.title,
      prompt: 'اقرأ الآية مع الإخفاء التدريجي ثم سمّعها.',
      hint: preview,
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: const [],
      correctAnswerText: resolver(index),
    );
  }

  MemorizationTestQuestionModel _noTextQuestion({
    required int index,
    required AyahTextResolver resolver,
  }) {
    return MemorizationTestQuestionModel(
      id: 'recite_$index',
      type: MemorizationQuestionType.noTextRecitation,
      title: MemorizationQuestionType.noTextRecitation.title,
      prompt: 'سمّع المقطع:\n${_scopeLabel(index, index)}',
      hint: 'سيتم إخفاء النص لتراجع حفظك، ثم قيّم أداءك.',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index,
      options: const [],
      correctAnswerText: resolver(index),
    );
  }

  MemorizationTestQuestionModel _fullPageQuestion({
    required int anchor,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
  }) {
    final local = allIndexes.indexOf(anchor);
    final startLocal = math.max(0, local - 3);
    final selected = allIndexes.skip(startLocal).take(8).toList();
    final start = selected.isEmpty ? anchor : selected.first;
    final end = selected.isEmpty ? anchor : selected.last;

    return MemorizationTestQuestionModel(
      id: 'full_page_${start}_$end',
      type: MemorizationQuestionType.fullPageRecitation,
      title: MemorizationQuestionType.fullPageRecitation.title,
      prompt: 'سمّع المقطع:\n${_scopeLabel(start, end)}',
      hint: 'سمّع بدون نظر، ثم راجع النص وقيّم أداءك.',
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end,
      options: const [],
      correctAnswerText: selected.map(resolver).join('\n'),
    );
  }

  List<MemorizationTestQuestionModel> _buildHiddenMushafQuestions({
    required List<int> indexes,
    required AyahTextResolver resolver,
  }) {
    if (indexes.isEmpty) return const [];
    final stride = math.max(1, (indexes.length / 24).ceil());
    final questions = <MemorizationTestQuestionModel>[];
    for (int offset = 0; offset < indexes.length; offset += stride) {
      final selected = indexes
          .skip(offset)
          .take(math.min(8, stride + 3))
          .toList();
      if (selected.isEmpty) continue;
      questions.add(
        MemorizationTestQuestionModel(
          id: 'hidden_mushaf_${selected.first}_${selected.last}',
          type: MemorizationQuestionType.hiddenMushafRecitation,
          title: MemorizationQuestionType.hiddenMushafRecitation.title,
          prompt: 'تسميع ذاتي:\n${_scopeLabel(selected.first, selected.last)}',
          hint: 'سنخفي الآيات لتسمّع المقطع لنفسك، ثم قيّم أداءك.',
          startGlobalAyahIndex: selected.first,
          endGlobalAyahIndex: selected.last,
          options: const [],
          correctAnswerText: selected.map(resolver).join('\n'),
        ),
      );
    }
    return questions;
  }

  List<MemorizationQuestionOption> _completionOptions({
    required int correctIndex,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
    required int seed,
  }) {
    final random = math.Random(seed);
    final selected = _candidateIndexes(correctIndex, allIndexes, random);

    return selected
        .map((index) {
          final parts = _splitAyah(resolver(index));
          return MemorizationQuestionOption(
            id: 'completion_$index',
            text: parts.end,
            isCorrect: index == correctIndex,
          );
        })
        .toList(growable: true)
      ..shuffle(random);
  }

  List<MemorizationQuestionOption> _buildChoiceOptions({
    required int correctIndex,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
    required int seed,
  }) {
    final random = math.Random(seed);
    final selected = _candidateIndexes(correctIndex, allIndexes, random);

    return selected
        .map(
          (index) => MemorizationQuestionOption(
            id: 'choice_$index',
            text: resolver(index),
            isCorrect: index == correctIndex,
          ),
        )
        .toList(growable: true)
      ..shuffle(random);
  }

  List<MemorizationQuestionOption> _buildTextSegmentOptions({
    required int correctIndex,
    required List<int> allIndexes,
    required AyahTextResolver resolver,
    required int seed,
    required String Function(String text) segmentResolver,
  }) {
    final random = math.Random(seed);
    final selected = _candidateIndexes(correctIndex, allIndexes, random);
    final correctText = segmentResolver(resolver(correctIndex)).trim();
    final usedTexts = <String>{};
    final options = <MemorizationQuestionOption>[];

    for (final index in selected) {
      final text = segmentResolver(resolver(index)).trim();
      if (text.isEmpty || !usedTexts.add(text)) continue;
      options.add(
        MemorizationQuestionOption(
          id: 'segment_${correctIndex}_$index',
          text: text,
          isCorrect: index == correctIndex,
        ),
      );
    }

    if (!options.any((option) => option.isCorrect)) {
      options.add(
        MemorizationQuestionOption(
          id: 'segment_${correctIndex}_correct',
          text: correctText,
          isCorrect: true,
        ),
      );
    }

    options.shuffle(random);
    return options;
  }

  List<int> _candidateIndexes(
    int correctIndex,
    List<int> allIndexes,
    math.Random random,
  ) {
    final candidates = <int>[
      correctIndex,
      ...allIndexes.where((index) => index != correctIndex),
    ];

    int before = correctIndex - 1;
    int after = correctIndex + 1;

    while (candidates.length < 4 &&
        (before >= 0 || after < QuranReaderHelpers.totalAyahs)) {
      if (before >= 0 && !candidates.contains(before)) candidates.add(before);
      if (candidates.length >= 4) break;
      if (after < QuranReaderHelpers.totalAyahs &&
          !candidates.contains(after)) {
        candidates.add(after);
      }
      before--;
      after++;
    }

    final distractors =
        candidates
            .where((index) => index != correctIndex)
            .toList(growable: true)
          ..shuffle(random);

    return <int>[correctIndex, ...distractors.take(3)];
  }

  List<MemorizationQuestionOption> _orderedItemOptions({
    required List<int> correctIndexes,
    required AyahTextResolver resolver,
    required int seed,
    required String idPrefix,
  }) {
    final random = math.Random(seed);

    return List<MemorizationQuestionOption>.generate(correctIndexes.length, (
      i,
    ) {
      final index = correctIndexes[i];
      return MemorizationQuestionOption(
        id: '${idPrefix}_$index',
        text: resolver(index),
        isCorrect: false,
        correctOrder: i,
      );
    })..shuffle(random);
  }

  bool _canSplitAyah(String text) => _words(text).length >= 5;

  bool _canBuildWordChoice(String text) => _words(text).length >= 4;

  bool _canBuildBoundaryQuestion(String text) => _words(text).length >= 8;

  bool _canBuildWordOrder(String text) {
    final count = _words(text).length;
    return count >= 4 && count <= 12;
  }

  _AyahSplit _splitAyah(String text) {
    final words = _words(text);
    if (words.length < 2) {
      return _AyahSplit(start: text, end: text);
    }

    final splitAt = (words.length / 2).floor().clamp(1, words.length - 1);
    return _AyahSplit(
      start: words.take(splitAt).join(' '),
      end: words.skip(splitAt).join(' '),
    );
  }

  List<String> _words(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _firstWords(String text, int count) {
    return _words(text).take(count).join(' ');
  }

  String _lastWords(String text, int count) {
    final words = _words(text);
    return words.skip(math.max(0, words.length - count)).join(' ');
  }

  String _suffixAfterWords(String text, int count) {
    return _words(text).skip(count).join(' ');
  }

  String _hideEveryOtherWord(String text) {
    final words = _words(text);
    if (words.isEmpty) return text;

    return List<String>.generate(words.length, (index) {
      if (index.isEven) return words[index];
      return '•••';
    }).join(' ');
  }

  String _defaultAyahLabel(int globalAyahIndex) {
    return _positionLabel(globalAyahIndex);
  }

  String _questionText(String fullHafsText) {
    final words = _words(fullHafsText);
    if (words.length <= 1) return fullHafsText.trim();
    final last = words.last;
    final isAyahMarker = last.runes.every(
      (rune) =>
          rune == 0x200F ||
          (rune >= 0xE000 && rune <= 0xF8FF) ||
          (rune >= 0xF0000 && rune <= 0xFFFFD),
    );
    return (isAyahMarker ? words.take(words.length - 1) : words).join(' ');
  }

  MemorizationTestQuestionModel _withFeedback(
    MemorizationTestQuestionModel question,
    AyahTextResolver fullTextResolver,
  ) {
    var feedbackStart = question.startGlobalAyahIndex;
    var feedbackEnd = question.endGlobalAyahIndex;
    if (question.type == MemorizationQuestionType.nextAyah) {
      feedbackStart = feedbackEnd;
    } else if (question.type == MemorizationQuestionType.previousAyah) {
      feedbackEnd = feedbackStart;
    } else if (question.ayahsCount > 1 &&
        question.type != MemorizationQuestionType.orderAyahs &&
        question.type != MemorizationQuestionType.fullPageRecitation &&
        question.type != MemorizationQuestionType.hiddenMushafRecitation) {
      feedbackEnd = feedbackStart;
    }

    final range = const QuranRangeLabelResolver().resolveAyahs(
      startGlobalAyahIndex: feedbackStart,
      endGlobalAyahIndex: feedbackEnd,
    );
    final fullText = List<String>.generate(
      feedbackEnd - feedbackStart + 1,
      (offset) => fullTextResolver(feedbackStart + offset),
    ).join('\n');
    return question.copyWith(
      fullAyahText: fullText,
      sourceLabel: range.displayLabel,
      pageLabel: range.pagesLabel,
    );
  }

  bool _isValidQuestion(MemorizationTestQuestionModel question) {
    final correctOptions = question.options
        .where((option) => option.isCorrect)
        .toList(growable: false);
    if (question.hasOptions && !question.isOrderingQuestion) {
      if (correctOptions.length != 1) return false;
      if (question.options.map((option) => option.text).toSet().length !=
          question.options.length) {
        return false;
      }
    }

    final promptSegment = _normalized(question.promptAyahText);
    final correct = _normalized(question.correctAnswerText);
    final prompt = _normalized(question.prompt);
    final hint = _normalized(question.hint);
    if (correct.isNotEmpty &&
        (prompt.contains(correct) || hint.contains(correct))) {
      return false;
    }
    if (promptSegment.isNotEmpty) {
      for (final option in question.options) {
        final optionText = _normalized(option.text);
        if (optionText == promptSegment ||
            optionText.startsWith(promptSegment) ||
            optionText.contains(promptSegment)) {
          return false;
        }
      }
    }
    return true;
  }

  String _normalized(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _scopeLabel(int startGlobalAyahIndex, int endGlobalAyahIndex) {
    final range = const QuranRangeLabelResolver().resolveAyahs(
      startGlobalAyahIndex: startGlobalAyahIndex,
      endGlobalAyahIndex: endGlobalAyahIndex,
    );
    return '${range.displayLabel}\n${range.pagesLabel}';
  }

  String _positionLabel(int globalAyahIndex) {
    final safe = globalAyahIndex
        .clamp(0, QuranReaderHelpers.totalAyahs - 1)
        .toInt();
    final position = QuranReaderHelpers.getPositionFromGlobalIndex(safe);
    final surahName = QuranReaderHelpers.getSuraName(position.suraIndex);

    return 'سورة $surahName، آية ${position.ayahIndex + 1}';
  }

  int _stableSeed(String value) {
    int hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _AyahSplit {
  const _AyahSplit({required this.start, required this.end});

  final String start;
  final String end;
}

class _ScoredQuestion {
  const _ScoredQuestion({required this.question, required this.score});

  final MemorizationTestQuestionModel question;
  final int score;
}
