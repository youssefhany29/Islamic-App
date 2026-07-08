import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class PrayerSoundPreviewPlayer {
  PrayerSoundPreviewPlayer._internal() {
    _audioPlayer.onPlayerComplete.listen((event) {
      currentSoundName.value = null;
    });
  }

  static final PrayerSoundPreviewPlayer _instance =
  PrayerSoundPreviewPlayer._internal();

  factory PrayerSoundPreviewPlayer() {
    return _instance;
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  final ValueNotifier<String?> currentSoundName = ValueNotifier<String?>(null);

  static const String _basePath = 'audio/prayer_notifications';

  Future<void> toggleSound(String soundName) async {
    if (currentSoundName.value == soundName) {
      await stop();
      return;
    }

    await playSound(soundName);
  }

  Future<void> playSound(String soundName) async {
    await stop();

    currentSoundName.value = soundName;

    try {
      await _audioPlayer.play(
        AssetSource('$_basePath/$soundName.mp3'),
      );
    } catch (error) {
      currentSoundName.value = null;
      debugPrint('❌ Failed to play prayer sound "$soundName": $error');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    currentSoundName.value = null;
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    currentSoundName.dispose();
  }
}