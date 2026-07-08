import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuranBookmark {
  final String id;
  final int suraIndex;
  final int ayahIndex;
  final int mushafPageNumber;
  final String viewMode;
  final String createdAt;

  const QuranBookmark({
    required this.id,
    required this.suraIndex,
    required this.ayahIndex,
    required this.mushafPageNumber,
    required this.viewMode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'suraIndex': suraIndex,
      'ayahIndex': ayahIndex,
      'mushafPageNumber': mushafPageNumber,
      'viewMode': viewMode,
      'createdAt': createdAt,
    };
  }

  factory QuranBookmark.fromMap(Map<String, dynamic> map) {
    return QuranBookmark(
      id: map['id'].toString(),
      suraIndex: map['suraIndex'] as int,
      ayahIndex: map['ayahIndex'] as int,
      mushafPageNumber: map['mushafPageNumber'] as int,
      viewMode: map['viewMode'].toString(),
      createdAt: map['createdAt'].toString(),
    );
  }
}

class QuranBookmarkStorage {
  static const String _bookmarksKey = 'quran_bookmarks';

  static Future<List<QuranBookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawBookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    return rawBookmarks.map((rawBookmark) {
      final decoded = jsonDecode(rawBookmark) as Map<String, dynamic>;
      return QuranBookmark.fromMap(decoded);
    }).toList();
  }

  static Future<void> addBookmark(QuranBookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    final alreadyExists = bookmarks.any((savedBookmark) {
      return savedBookmark.suraIndex == bookmark.suraIndex &&
          savedBookmark.ayahIndex == bookmark.ayahIndex &&
          savedBookmark.mushafPageNumber == bookmark.mushafPageNumber;
    });

    if (!alreadyExists) {
      bookmarks.insert(0, bookmark);
    }

    final encodedBookmarks = bookmarks.map((bookmark) {
      return jsonEncode(bookmark.toMap());
    }).toList();

    await prefs.setStringList(_bookmarksKey, encodedBookmarks);
  }

  static Future<void> deleteBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    bookmarks.removeWhere((bookmark) => bookmark.id == id);

    final encodedBookmarks = bookmarks.map((bookmark) {
      return jsonEncode(bookmark.toMap());
    }).toList();

    await prefs.setStringList(_bookmarksKey, encodedBookmarks);
  }

  static Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarksKey);
  }
}