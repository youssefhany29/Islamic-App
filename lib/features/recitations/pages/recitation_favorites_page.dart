import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/recitation_favorite_model.dart';
import '../services/recitation_api_service.dart';
import '../services/recitation_download_service.dart';
import '../services/recitation_favorites_storage.dart';
import '../services/recitation_progress_storage.dart';
import 'recitation_player_page.dart';
import 'reciter_surahs_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class RecitationFavoritesPage extends StatefulWidget {
  const RecitationFavoritesPage({super.key});

  @override
  State<RecitationFavoritesPage> createState() =>
      _RecitationFavoritesPageState();
}

class _RecitationFavoritesPageState extends State<RecitationFavoritesPage> {
  bool isLoading = true;
  List<RecitationFavoriteModel> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final result = await RecitationFavoritesStorage.loadFavorites();

    if (!mounted) return;

    setState(() {
      favorites = result;
      isLoading = false;
    });
  }

  Future<void> _removeFavorite(RecitationFavoriteModel favorite) async {
    AppHaptics.tap(context);

    await RecitationFavoritesStorage.removeFavorite(favorite.id);
    await _loadFavorites();
  }

  Future<void> _openFavorite(RecitationFavoriteModel favorite) async {
    AppHaptics.tap(context);

    if (favorite.isReciterFavorite) {
      try {
        final reciters = await RecitationApiService.getReciters();

        final reciter = reciters.firstWhere(
          (item) =>
              item.id == favorite.reciterId &&
              item.source == favorite.reciterSource,
        );

        if (!mounted) return;

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ReciterSurahsPage(reciter: reciter),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        ).then((_) => _loadFavorites());
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(context, 'تعذر فتح القارئ الآن، حاول مرة أخرى'),
        );
      }

      return;
    }

    final surahNumber = favorite.surahNumber;
    final surahName = favorite.surahName;

    if (surahNumber == null || surahName == null) return;

    final downloaded = await RecitationDownloadService.getDownload(
      reciterId: favorite.reciterId,
      source: favorite.reciterSource,
      surahNumber: surahNumber,
    );

    final progress = await RecitationProgressStorage.getSavedProgressInfo(
      reciterId: favorite.reciterId,
      reciterSource: favorite.reciterSource,
      surahNumber: surahNumber,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecitationPlayerPage(
              reciterId: favorite.reciterId,
              reciterName: favorite.reciterName,
              reciterSource: favorite.reciterSource,
              mp3QuranServerUrl: favorite.mp3QuranServerUrl,
              surahNumber: surahNumber,
              surahName: surahName,
              initialAudioUrl: downloaded?.audioUrl,
              localFilePath: downloaded?.localFilePath,
              startPosition: progress.position,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadFavorites());
  }

  SnackBar _snackBar(BuildContext context, String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 38.w,
                        minHeight: 38.h,
                      ),
                      onPressed: () {
                        AppHaptics.tap(context);
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: textColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'المفضلة',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.headline(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 38.w),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : favorites.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد مفضلة بعد',
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: textColor.withOpacity(0.65)),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: favorites.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final favorite = favorites[index];

                          return _FavoriteTile(
                            favorite: favorite,
                            onTap: () => _openFavorite(favorite),
                            onRemove: () => _removeFavorite(favorite),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final RecitationFavoriteModel favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteTile({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    final isSurah = favorite.isSurahFavorite;

    final title = isSurah
        ? 'سورة ${favorite.surahName ?? ''}'
        : favorite.reciterName;

    final subtitle = isSurah ? favorite.reciterName : 'قارئ مفضل';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 66.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: textColor.withOpacity(0.08)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 21.r,
                backgroundColor: primary.withOpacity(0.12),
                child: Icon(
                  isSurah
                      ? Icons.menu_book_rounded
                      : Icons.record_voice_over_rounded,
                  color: primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, color: textColor),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: textColor.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.star_rounded,
                  color: const Color(0xffffb300),
                  size: 22.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
