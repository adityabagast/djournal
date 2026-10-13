import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.audioPath,
    required this.durationMs,
    required this.transcript,
  });

  final String audioPath;
  final int durationMs;
  final String transcript;
}

/// Service untuk merekam suara sekaligus mentranskripsi ucapan (speech-to-text).
class VoiceRecorderService extends ChangeNotifier {
  VoiceRecorderService() {
    _recorder = AudioRecorder();
    _speech = SpeechToText();
  }

  static const _uuid = Uuid();

  late final AudioRecorder _recorder;
  late final SpeechToText _speech;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String? _currentAudioPath;
  String? get currentAudioPath => _currentAudioPath;

  int _elapsedMilliseconds = 0;
  int get elapsedMilliseconds => _elapsedMilliseconds;

  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  double _currentAmplitude = 0.0;
  double get currentAmplitude => _currentAmplitude;

  bool _speechInitialized = false;
  bool _speechAvailable = false;
  bool get isSpeechAvailable => _speechAvailable;

  Timer? _ticker;
  StreamSubscription<Amplitude>? _amplitudeSub;

  /// Cek izin mikrofon untuk perekam audio.
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('hasPermission error: $e');
      return false;
    }
  }

  /// Inisialisasi mesin Speech-to-Text secara on-device.
  Future<bool> initSpeech() async {
    if (_speechInitialized) return _speechAvailable;
    try {
      _speechAvailable = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          debugPrint('SpeechToText onError: ${error.errorMsg} (${error.permanent})');
        },
        onStatus: (String status) {
          debugPrint('SpeechToText onStatus: $status');
        },
      );
      _speechInitialized = true;
    } catch (e) {
      debugPrint('SpeechToText init error: $e');
      _speechAvailable = false;
      _speechInitialized = true;
    }
    return _speechAvailable;
  }

  /// Mulai merekam suara dan/atau speech-to-text.
  Future<bool> startRecording({
    bool recordAudio = true,
    bool enableSpeech = false,
  }) async {
    if (_isRecording) return false;

    final permitted = await hasPermission();
    if (!permitted) return false;

    try {
      _isRecording = true;
      _elapsedMilliseconds = 0;
      _liveTranscript = '';
      _currentAmplitude = 0.0;

      // Timer ticker setiap 100ms
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _elapsedMilliseconds += 100;
        notifyListeners();
      });

      if (recordAudio) {
        // Siapkan direktori penyimpanan file audio
        final appDir = await getApplicationDocumentsDirectory();
        final voiceDir = Directory(p.join(appDir.path, 'voice_notes'));
        if (!await voiceDir.exists()) {
          await voiceDir.create(recursive: true);
        }

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.m4a';
        final filePath = p.join(voiceDir.path, fileName);
        _currentAudioPath = filePath;

        // Mulai AudioRecorder dengan format AAC/M4A hemat ruang
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 44100,
            androidConfig: AndroidRecordConfig(
              manageBluetooth: false,
            ),
          ),
          path: filePath,
        );

        // Stream amplitude untuk visualisasi gelombang
        _amplitudeSub?.cancel();
        _amplitudeSub = _recorder
            .onAmplitudeChanged(const Duration(milliseconds: 100))
            .listen((amp) {
          final db = amp.current;
          if (db.isFinite) {
            final normalized = ((db + 60) / 60).clamp(0.0, 1.0);
            _currentAmplitude = normalized;
          }
          notifyListeners();
        });
      }

      if (enableSpeech) {
        await _startSpeechListening();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('startRecording error: $e');
      await cancelRecording();
      return false;
    }
  }

  Future<void> _startSpeechListening() async {
    try {
      final available = await initSpeech();
      if (!available) return;

      // Cari locale bahasa Indonesia jika ada
      String? localeId;
      try {
        final locales = await _speech.locales();
        final idLocale = locales.firstWhere(
          (loc) => loc.localeId.toLowerCase().startsWith('id'),
          orElse: () => locales.first,
        );
        localeId = idLocale.localeId;
      } catch (_) {}

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _liveTranscript = result.recognizedWords;
          notifyListeners();
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          localeId: localeId,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
    }
  }

  /// Berhenti merekam dan mengembalikan hasil (audio path + durasi + transkripsi).
  Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    _ticker?.cancel();
    _amplitudeSub?.cancel();

    String? savedPath;
    try {
      if (_currentAudioPath != null) {
        savedPath = await _recorder.stop();
      }
    } catch (e) {
      debugPrint('recorder.stop error: $e');
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('speech.stop error: $e');
    }

    final duration = _elapsedMilliseconds;
    final transcript = _liveTranscript.trim();
    final path = savedPath ?? _currentAudioPath;

    _isRecording = false;
    _currentAudioPath = null;
    _elapsedMilliseconds = 0;
    _currentAmplitude = 0.0;
    notifyListeners();

    if (path != null && await File(path).exists()) {
      return VoiceRecordingResult(
        audioPath: path,
        durationMs: duration,
        transcript: transcript,
      );
    } else {
      return VoiceRecordingResult(
        audioPath: '',
        durationMs: duration,
        transcript: transcript,
      );
    }
  }

  /// Batalkan rekaman dan hapus file audio yang sempat dibuat.
  Future<void> cancelRecording() async {
    _ticker?.cancel();
    _amplitudeSub?.cancel();

    try {
      await _recorder.stop();
    } catch (_) {}

    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {}

    if (_currentAudioPath != null) {
      try {
        final file = File(_currentAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    _isRecording = false;
    _currentAudioPath = null;
    _elapsedMilliseconds = 0;
    _liveTranscript = '';
    _currentAmplitude = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    _speech.cancel();
    super.dispose();
  }
}
