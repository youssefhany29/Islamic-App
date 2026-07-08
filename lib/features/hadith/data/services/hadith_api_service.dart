import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class HadithApiBookModel {
  const HadithApiBookModel({
    required this.bookSlug,
    required this.bookName,
    required this.url,
    this.writerName,
    this.aboutWriter,
  });

  final String bookSlug;
  final String bookName;
  final String url;
  final String? writerName;
  final String? aboutWriter;
}

class HadithApiHadithModel {
  const HadithApiHadithModel({
    required this.id,
    required this.textArabic,
    this.bookSlug,
    this.bookName,
    this.chapter,
    this.hadithNumber,
    this.status,
  });

  final String id;
  final String textArabic;
  final String? bookSlug;
  final String? bookName;
  final String? chapter;
  final String? hadithNumber;
  final String? status;

  factory HadithApiHadithModel.fromJson({
    required Map<String, dynamic> json,
    required HadithApiBookModel book,
    required int fallbackIndex,
  }) {
    final String number =
        (json['hadithnumber'] ??
                json['hadithNumber'] ??
                json['arabicnumber'] ??
                json['number'] ??
                json['id'] ??
                fallbackIndex)
            .toString();

    final String text =
        (json['text'] ??
                json['arabic'] ??
                json['hadithArabic'] ??
                json['hadith'] ??
                '')
            .toString()
            .trim();

    final String? chapter =
        (json['chapter'] ??
                json['chapterName'] ??
                json['book'] ??
                json['section'])
            ?.toString();

    final dynamic gradesRaw = json['grades'];
    String? grade;

    if (gradesRaw is List && gradesRaw.isNotEmpty) {
      final firstGrade = gradesRaw.first;

      if (firstGrade is Map) {
        grade =
            (firstGrade['grade'] ?? firstGrade['name'] ?? firstGrade['status'])
                ?.toString();
      } else {
        grade = firstGrade.toString();
      }
    } else {
      grade = (json['grade'] ?? json['status'])?.toString();
    }

    return HadithApiHadithModel(
      id: '${book.bookSlug}_$number',
      textArabic: text,
      bookSlug: book.bookSlug,
      bookName: book.bookName,
      chapter: chapter,
      hadithNumber: number,
      status: grade,
    );
  }
}

class HadithApiService {
  const HadithApiService();

  static const String _baseCdn =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  static const String _cachePrefix = 'fawaz_hadith_book_cache_';

  static const List<HadithApiBookModel> supportedBooks = [
    HadithApiBookModel(
      bookSlug: 'ara-bukhari',
      bookName: 'صحيح البخاري',
      url: '$_baseCdn/ara-bukhari.min.json',
      writerName: 'الإمام البخاري',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-muslim',
      bookName: 'صحيح مسلم',
      url: '$_baseCdn/ara-muslim.min.json',
      writerName: 'الإمام مسلم',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-abudawud',
      bookName: 'سنن أبي داود',
      url: '$_baseCdn/ara-abudawud.min.json',
      writerName: 'أبو داود',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-tirmidhi',
      bookName: 'جامع الترمذي',
      url: '$_baseCdn/ara-tirmidhi.min.json',
      writerName: 'الإمام الترمذي',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-nasai',
      bookName: 'سنن النسائي',
      url: '$_baseCdn/ara-nasai.min.json',
      writerName: 'الإمام النسائي',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-ibnmajah',
      bookName: 'سنن ابن ماجه',
      url: '$_baseCdn/ara-ibnmajah.min.json',
      writerName: 'ابن ماجه',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-malik',
      bookName: 'موطأ مالك',
      url: '$_baseCdn/ara-malik.min.json',
      writerName: 'الإمام مالك',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-nawawi',
      bookName: 'الأربعون النووية',
      url: '$_baseCdn/ara-nawawi.min.json',
      writerName: 'الإمام النووي',
    ),
    HadithApiBookModel(
      bookSlug: 'ara-qudsi',
      bookName: 'الأحاديث القدسية',
      url: '$_baseCdn/ara-qudsi.min.json',
      writerName: 'مجموعة أحاديث قدسية',
    ),
  ];

  Future<List<HadithApiBookModel>> getBooks() async {
    return supportedBooks;
  }

  Future<List<HadithApiHadithModel>> getHadiths({
    HadithApiBookModel? book,
    String? arabicSearch,
    int limit = 80,
  }) async {
    final HadithApiBookModel selectedBook = book ?? supportedBooks.first;
    final decoded = await _getJsonWithCache(selectedBook);

    final List<dynamic> rawHadiths = _extractHadithList(decoded);
    final List<HadithApiHadithModel> parsed = [];

    for (int index = 0; index < rawHadiths.length; index++) {
      final raw = rawHadiths[index];

      if (raw is! Map) continue;

      final hadith = HadithApiHadithModel.fromJson(
        json: raw.cast<String, dynamic>(),
        book: selectedBook,
        fallbackIndex: index + 1,
      );

      if (hadith.textArabic.trim().isEmpty) continue;

      parsed.add(hadith);
    }

    final String normalizedSearch = _normalizeArabic(arabicSearch ?? '');

    final List<HadithApiHadithModel> filtered = normalizedSearch.isEmpty
        ? parsed
        : parsed.where((hadith) {
            final text = _normalizeArabic(hadith.textArabic);
            final bookName = _normalizeArabic(hadith.bookName ?? '');
            final chapter = _normalizeArabic(hadith.chapter ?? '');

            return text.contains(normalizedSearch) ||
                bookName.contains(normalizedSearch) ||
                chapter.contains(normalizedSearch);
          }).toList();

    if (limit <= 0 || filtered.length <= limit) {
      return filtered;
    }

    return filtered.take(limit).toList();
  }

  Future<bool> hasCachedBook(HadithApiBookModel book) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('$_cachePrefix${book.bookSlug}') != null;
  }

  Future<dynamic> _getJsonWithCache(HadithApiBookModel book) async {
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = '$_cachePrefix${book.bookSlug}';

    try {
      final uri = Uri.parse(book.url);
      final decoded = await _getJsonFromNetwork(uri);

      await prefs.setString(cacheKey, jsonEncode(decoded));

      return decoded;
    } catch (_) {
      final cached = prefs.getString(cacheKey);

      if (cached != null && cached.trim().isNotEmpty) {
        return jsonDecode(cached);
      }

      rethrow;
    }
  }

  List<dynamic> _extractHadithList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      final candidates = [
        decoded['hadiths'],
        decoded['data'],
        decoded['items'],
        decoded['ahadith'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;

        if (candidate is Map && candidate['data'] is List) {
          return candidate['data'] as List;
        }
      }
    }

    return [];
  }

  Future<dynamic> _getJsonFromNetwork(Uri uri) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Fawaz Hadith API error ${response.statusCode}: $body',
          uri: uri,
        );
      }

      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  String _normalizeArabic(String input) {
    return input
        .toLowerCase()
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll('ـ', '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
