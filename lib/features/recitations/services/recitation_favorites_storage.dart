import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recitation_favorite_model.dart';
import '../models/reciter_model.dart';

class RecitationFavoritesStorage {
  RecitationFavoritesStorage._();

  static const String _favoritesKey = 'recitation_favorites';

  static Future<List<RecitationFavoriteModel>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);

    if (raw == null || raw.trim().isEmpty) {
      return <RecitationFavoriteModel>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <RecitationFavoriteModel>[];
      }

      final favorites = decoded
          .whereType<Map>()
          .map(
            (item) => RecitationFavoriteModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((item) => item.id.trim().isNotEmpty)
          .toList();

      favorites.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

      return favorites;
    } catch (_) {
      return <RecitationFavoriteModel>[];
    }
  }

  static Future<void> _saveFavorites(
      List<RecitationFavoriteModel> favorites,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _favoritesKey,
      jsonEncode(
        favorites.map((item) => item.toJson()).toList(),
      ),
    );
  }

  static Future<bool> isFavoriteReciter({
    required int reciterId,
    required RecitationSource reciterSource,
  }) async {
    final favorites = await loadFavorites();
    final key = RecitationFavoriteModel.reciterKey(
      reciterId: reciterId,
      reciterSource: reciterSource,
    );

    return favorites.any((item) => item.id == key);
  }

  static Future<bool> isFavoriteSurah({
    required int reciterId,
    required RecitationSource reciterSource,
    required int surahNumber,
  }) async {
    final favorites = await loadFavorites();
    final key = RecitationFavoriteModel.surahKey(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
    );

    return favorites.any((item) => item.id == key);
  }

  static Future<bool> hasFavorites() async {
    final favorites = await loadFavorites();
    return favorites.isNotEmpty;
  }

  static Future<void> toggleReciterFavorite({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
  }) async {
    final favorites = await loadFavorites();

    final key = RecitationFavoriteModel.reciterKey(
      reciterId: reciterId,
      reciterSource: reciterSource,
    );

    final exists = favorites.any((item) => item.id == key);

    if (exists) {
      favorites.removeWhere((item) => item.id == key);
    } else {
      favorites.insert(
        0,
        RecitationFavoriteModel.reciter(
          reciterId: reciterId,
          reciterName: reciterName,
          reciterSource: reciterSource,
          mp3QuranServerUrl: mp3QuranServerUrl,
        ),
      );
    }

    await _saveFavorites(favorites);
  }

  static Future<void> toggleSurahFavorite({
    required int reciterId,
    required String reciterName,
    required RecitationSource reciterSource,
    required String mp3QuranServerUrl,
    required int surahNumber,
    required String surahName,
  }) async {
    final favorites = await loadFavorites();

    final key = RecitationFavoriteModel.surahKey(
      reciterId: reciterId,
      reciterSource: reciterSource,
      surahNumber: surahNumber,
    );

    final exists = favorites.any((item) => item.id == key);

    if (exists) {
      favorites.removeWhere((item) => item.id == key);
    } else {
      favorites.insert(
        0,
        RecitationFavoriteModel.surah(
          reciterId: reciterId,
          reciterName: reciterName,
          reciterSource: reciterSource,
          mp3QuranServerUrl: mp3QuranServerUrl,
          surahNumber: surahNumber,
          surahName: surahName,
        ),
      );
    }

    await _saveFavorites(favorites);
  }

  static Future<void> removeFavorite(String id) async {
    final favorites = await loadFavorites();

    favorites.removeWhere((item) => item.id == id);

    await _saveFavorites(favorites);
  }

  static Future<void> clearFavorites() async {
    await _saveFavorites([]);
  }
}