import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart' as ar;
import 'package:path_provider/path_provider.dart';

import 'phrase.dart';
import '../models/image_phrase.dart';
import 'web_audio_cache.dart';

final class AudioRecorder extends ChangeNotifier {
  dynamic _phrase;
  final _recorder = ar.AudioRecorder();
  var _isRecording = false;

  bool get isRecording => _isRecording;

  void updateAudioPathForPhrase(dynamic phrase) {
    _phrase = phrase;
  }

  void start() {
    if (_phrase == null) {
      throw StateError('Audio path is not set!');
    }
    _isRecording = true;
    notifyListeners();
    _recorder.hasPermission().then((hasPermission) async {
      if (hasPermission) {
        String? path;
        if (kIsWeb) {
          path = null;
        } else {
          if (_phrase is Phrase) {
            path = await _phrase.localTempPath;
          } else if (_phrase is ImagePhrase) {
            path = await _phrase.localTempPath;
          } else {
            throw StateError('Unsupported phrase type');
          }
        }
        
        _recorder.start(
          const ar.RecordConfig(
            encoder: ar.AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            autoGain: true,
            echoCancel: true,
            noiseSuppress: true,
          ),
          path: path ?? '',
        );
      }
    });
  }

  Future<void> stop() async {
    if (isRecording) {
      final path = await _recorder.stop();
      
      if (kIsWeb) {
        if (_phrase is Phrase) {
          WebAudioCache.setAudioUrl(_phrase.index, path);
        } else if (_phrase is ImagePhrase) {
          WebAudioCache.setImageAudioUrl(_phrase.index, path);
        }
      } else {
        // Check if temp file exists before renaming
        final tempFile = File(await _getTempPath());
        if (await tempFile.exists()) {
          await tempFile.rename(await _getFinalPath());
        }
      }
      
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<String> _getTempPath() async {
    if (kIsWeb) return '';
    if (_phrase is Phrase) {
      return await (_phrase as Phrase).localTempPath;
    } else if (_phrase is ImagePhrase) {
      return await (_phrase as ImagePhrase).localTempPath;
    } else {
      throw StateError('Unsupported phrase type');
    }
  }

  Future<String> _getFinalPath() async {
    if (kIsWeb) return '';
    if (_phrase is Phrase) {
      return await (_phrase as Phrase).localRecordingPath;
    } else if (_phrase is ImagePhrase) {
      return await (_phrase as ImagePhrase).localRecordingPath;
    } else {
      throw StateError('Unsupported phrase type');
    }
  }
}
