import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'svg_mushaf_geometry_models.dart';

class SvgMushafGeometryRepository {
  SvgMushafGeometryRepository._();

  static final SvgMushafGeometryRepository instance =
      SvgMushafGeometryRepository._();

  static const int _maxCachedPages = 16;

  final LinkedHashMap<int, SvgPageGeometry> _cache =
      LinkedHashMap<int, SvgPageGeometry>();
  final Map<int, Future<SvgPageGeometry>> _loading =
      <int, Future<SvgPageGeometry>>{};

  SvgPageGeometry? getCachedPage(int pageNumber) {
    final int safePage = _safePage(pageNumber);
    final SvgPageGeometry? geometry = _cache.remove(safePage);
    if (geometry == null) {
      return null;
    }
    _cache[safePage] = geometry;
    return geometry;
  }

  Future<SvgPageGeometry> loadPage(int pageNumber) {
    final int safePage = _safePage(pageNumber);
    final SvgPageGeometry? cached = getCachedPage(safePage);
    if (cached != null) {
      return Future<SvgPageGeometry>.value(cached);
    }

    final Future<SvgPageGeometry>? running = _loading[safePage];
    if (running != null) {
      return running;
    }

    final Future<SvgPageGeometry> task = _loadPageFromAssets(safePage);
    _loading[safePage] = task;
    return task.whenComplete(() {
      _loading.remove(safePage);
    });
  }

  Future<void> warmPageWindow(int pageNumber, {int radius = 2}) async {
    final int safePage = _safePage(pageNumber);
    for (final int page in _priorityPages(safePage, radius: radius)) {
      await loadPage(page);
      await Future<void>.delayed(Duration.zero);
    }
    retainPagesAround(safePage, radius: radius + 2);
  }

  void retainPagesAround(int pageNumber, {required int radius}) {
    final int safePage = _safePage(pageNumber);
    final int minPage = _safePage(safePage - radius);
    final int maxPage = _safePage(safePage + radius);

    _cache.removeWhere((page, _) => page < minPage || page > maxPage);
    while (_cache.length > _maxCachedPages) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<SvgPageGeometry> _loadPageFromAssets(int pageNumber) async {
    final String text = await rootBundle.loadString(_geometryAsset(pageNumber));
    final SvgPageGeometry geometry = SvgPageGeometry.fromJson(
      jsonDecode(text) as Map<String, Object?>,
    );
    _cache[pageNumber] = geometry;
    while (_cache.length > _maxCachedPages) {
      _cache.remove(_cache.keys.first);
    }
    return geometry;
  }

  List<int> _priorityPages(int pageNumber, {required int radius}) {
    final List<int> pages = <int>[pageNumber];
    for (int offset = 1; offset <= radius; offset++) {
      final int next = pageNumber + offset;
      final int previous = pageNumber - offset;
      if (next <= 604) {
        pages.add(next);
      }
      if (previous >= 1) {
        pages.add(previous);
      }
    }
    return pages;
  }

  static int _safePage(int pageNumber) {
    return pageNumber.clamp(1, 604).toInt();
  }

  static String _geometryAsset(int pageNumber) {
    return 'assets/quran/svg_geometry_quran_only/pages/page_${pageNumber.toString().padLeft(3, '0')}.json';
  }
}
