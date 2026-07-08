import 'package:audioplayers/audioplayers.dart';

class AzanPlayer {
  static final AzanPlayer _instance = AzanPlayer._internal();
  factory AzanPlayer() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  AzanPlayer._internal();

  void playAzan() async {
    await _audioPlayer.play(AssetSource(''));
  }
}
