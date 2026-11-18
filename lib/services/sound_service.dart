import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _fxPlayer = AudioPlayer();
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  Future<void> playEffect(String assetName) async {
    if (!soundEnabled) return;
    try {
      await _fxPlayer.stop();
      await _fxPlayer.play(AssetSource('audio/$assetName'), volume: 0.65);
    } catch (_) {
      // Ignore audio failures in headless test environments or unsupported codecs.
    }
  }

  void lightHaptic() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  void mediumHaptic() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
  }

  void heavyHaptic() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
  }
}
