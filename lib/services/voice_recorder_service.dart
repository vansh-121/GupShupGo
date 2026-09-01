import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service that records audio using Android's native MediaRecorder
/// via a MethodChannel. No third-party recording dependency needed.
///
/// Also keeps track of recording duration via a periodic timer
/// so the UI can show a live stopwatch.
class VoiceRecorderService extends ChangeNotifier {
  static const _channel = MethodChannel('com.gupshupgo.app/audio_recorder');

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  Timer? _timer;
  String? _currentPath;

  /// Cap for the current recording in seconds, or `null` for uncapped.
  ///
  /// Held here rather than in the UI because the recorder is driven from two
  /// screens (`chat_screen` and `mesh_chat_screen`) and a cap enforced in only
  /// one of them is not a cap.
  int? _maxDurationSec;
  int? get maxDurationSec => _maxDurationSec;

  VoidCallback? _onLimitReached;

  /// Whether [_onLimitReached] has already fired for this recording. The ticker
  /// keeps running until the callback's `stopRecording` completes, so without
  /// this the send would be triggered once per second.
  bool _limitFired = false;

  /// Seconds left before the cap stops this recording, or `null` when uncapped.
  Duration? get remaining {
    final cap = _maxDurationSec;
    if (cap == null) return null;
    final left = cap - _elapsed.inSeconds;
    return Duration(seconds: left < 0 ? 0 : left);
  }

  /// Start recording audio to a temp .m4a file.
  /// Returns the path where the file will be written, or null on failure.
  ///
  /// Pass [maxDurationSec] to cap the recording — `null` means uncapped. On
  /// reaching the cap the ticker fires [onLimitReached] exactly once; the
  /// callback owns what happens next (the chat screens stop and send, so the
  /// user keeps the audio they had already recorded rather than losing it).
  Future<String?> startRecording({
    int? maxDurationSec,
    VoidCallback? onLimitReached,
  }) async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('[VoiceRecorder] Microphone permission denied');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _channel.invokeMethod('startRecording', {'path': filePath});

      _currentPath = filePath;
      _isRecording = true;
      _elapsed = Duration.zero;
      _maxDurationSec = maxDurationSec;
      _onLimitReached = onLimitReached;
      _limitFired = false;
      _startTimer();
      notifyListeners();

      return filePath;
    } catch (e) {
      debugPrint('[VoiceRecorder] Error starting: $e');
      return null;
    }
  }

  /// Stop recording and return the file path of the recorded audio.
  Future<String?> stopRecording() async {
    try {
      _stopTimer();
      await _channel.invokeMethod('stopRecording');
      _isRecording = false;
      notifyListeners();
      return _currentPath;
    } catch (e) {
      debugPrint('[VoiceRecorder] Error stopping: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel the current recording and delete the temp file.
  Future<void> cancelRecording() async {
    try {
      _stopTimer();
      await _channel.invokeMethod('stopRecording');
      _isRecording = false;
      _elapsed = Duration.zero;
      notifyListeners();

      // Delete the partially-recorded file
      if (_currentPath != null) {
        final file = File(_currentPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentPath = null;
      }
    } catch (e) {
      debugPrint('[VoiceRecorder] Error cancelling: $e');
      _isRecording = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();

      final cap = _maxDurationSec;
      if (cap != null && !_limitFired && _elapsed.inSeconds >= cap) {
        // Latch before invoking: the callback's stop is async, so this ticker
        // gets at least one more tick before `_isRecording` goes false.
        _limitFired = true;
        _onLimitReached?.call();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    // Drop the cap and its callback with the ticker that used them. A stale
    // `_onLimitReached` closure holds a reference to the screen that started the
    // recording, and a stale `_maxDurationSec` would make `remaining` report a
    // countdown for a recording that is no longer running.
    _maxDurationSec = null;
    _onLimitReached = null;
  }

  /// Format a duration as mm:ss.
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _stopTimer();
    if (_isRecording) {
      _channel.invokeMethod('stopRecording').catchError((_) {});
    }
    super.dispose();
  }
}
