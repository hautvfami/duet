import 'package:duet/duet_method_channel.dart';

import 'duet_platform_interface.dart';

class Duet {
  Future<void> onNativeCall({
    OnVideoRecorded? onVideoRecorded,
    OnAudioReceived? onAudioReceived,
    OnVideoMerged? onVideoMerged,
    OnTimerVideoReceived? onTimerVideoReceived,
  }) async {
    return DuetPlatform.instance.onNativeCall(
      onAudioReceived: onAudioReceived,
      onVideoMerged: onVideoMerged,
      onVideoRecorded: onVideoRecorded,
      onTimerVideoReceived: onTimerVideoReceived,
    );
  }

  Future<String?> recordDuet() => DuetPlatform.instance.recordDuet();

  Future<String?> resumeDuet() => DuetPlatform.instance.resumeDuet();

  Future<String?> pauseDuet() => DuetPlatform.instance.pauseDuet();

  Future<String?> recordAudio() => DuetPlatform.instance.recordAudio();

  Future<String?> pauseAudio() => DuetPlatform.instance.pauseAudio();

  Future<String?> playSound(String url) => DuetPlatform.instance.playSound(url);

  Future<String?> saveVideoToAlbum(String path) =>
      DuetPlatform.instance.saveVideoToAlbum(path);
}
