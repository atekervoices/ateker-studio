import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modes/upload_status.dart';
import 'phrase.dart';
import 'phrases_repository.dart';
import '../ui/core/themes/colors.dart';

final class Uploader extends ChangeNotifier {
  static const _uploadQueueKey = 'UPLOAD_QUEUE_V1';

  UploadStatus _uploadStatus = UploadStatus.notStarted;
  Timer? _timer;

  final Queue<int> _queue = Queue<int>();
  final Map<int, UploadStatus> _phraseUploadStatus = <int, UploadStatus>{};

  PhrasesRepository? _phrasesRepository;
  Timer? _retryTimer;
  bool _isProcessing = false;

  Icon get uploadIcon {
    switch (_uploadStatus) {
      case UploadStatus.notStarted:
        return const Icon(Icons.cloud_upload, color: Colors.transparent);
      case UploadStatus.queued:
        return const Icon(Icons.cloud_upload, color: AppColors.primary);
      case UploadStatus.started:
        return const Icon(Icons.cloud_upload, color: AppColors.primary);
      case UploadStatus.completed:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case UploadStatus.interrupted:
        return const Icon(Icons.cloud_off, color: Colors.red);
    }
  }

  bool get showProgressIndicator => (_uploadStatus == UploadStatus.started);

  bool get showUploadProgressIcon {
    switch (_uploadStatus) {
      case UploadStatus.notStarted:
        return false;
      case UploadStatus.queued:
        return true;
      case UploadStatus.started:
        return true;
      case UploadStatus.completed:
        return true;
      case UploadStatus.interrupted:
        return true;
    }
  }

  int get queuedCount => _queue.length;

  UploadStatus statusForPhrase(int phraseIndex) {
    return _phraseUploadStatus[phraseIndex] ?? UploadStatus.notStarted;
  }

  int get uploadedCount {
    return _phraseUploadStatus.values
        .where((status) => status == UploadStatus.completed)
        .length;
  }

  Future<void> attachPhrasesRepository(PhrasesRepository repo) async {
    _phrasesRepository = repo;
    await _loadQueueFromPrefs();
    _scheduleRetryLoop();
    unawaited(processQueue());
  }

  Future<void> enqueuePhrase(Phrase phrase) async {
    final index = phrase.index;
    if (_phraseUploadStatus[index] == UploadStatus.completed) {
      return;
    }
    if (!_queue.contains(index)) {
      _queue.add(index);
    }
    _phraseUploadStatus[index] = UploadStatus.queued;
    _uploadStatus = UploadStatus.queued;
    notifyListeners();
    await _persistQueueToPrefs();
    unawaited(processQueue());
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    final repo = _phrasesRepository;
    if (repo == null) return;
    if (_queue.isEmpty) {
      _uploadStatus = UploadStatus.notStarted;
      notifyListeners();
      return;
    }

    _isProcessing = true;
    try {
      while (_queue.isNotEmpty) {
        final phraseIndex = _queue.first;
        final Phrase phrase = repo.phrases[phraseIndex];
        _phraseUploadStatus[phraseIndex] = UploadStatus.started;
        updateStatus(status: UploadStatus.started);
        try {
          await phrase.uploadRecording();
          _queue.removeFirst();
          _phraseUploadStatus[phraseIndex] = UploadStatus.completed;
          await _persistQueueToPrefs();
          updateStatus(status: UploadStatus.completed);
        } catch (_) {
          _phraseUploadStatus[phraseIndex] = UploadStatus.interrupted;
          updateStatus(status: UploadStatus.interrupted);
          await _persistQueueToPrefs();
          _scheduleRetryLoop();
          break;
        }
      }
    } finally {
      _isProcessing = false;
      if (_queue.isEmpty) {
        _uploadStatus = UploadStatus.notStarted;
        notifyListeners();
      } else if (_uploadStatus != UploadStatus.started) {
        _uploadStatus = UploadStatus.queued;
        notifyListeners();
      }
    }
  }

  void updateStatus({required UploadStatus status}) {
    _uploadStatus = status;
    notifyListeners();
    if (_uploadStatus == UploadStatus.completed) {
      _timer = Timer(const Duration(seconds: 1, milliseconds: 500), () {
        if (_queue.isNotEmpty) {
          _uploadStatus = UploadStatus.queued;
        } else {
          _uploadStatus = UploadStatus.notStarted;
        }
        notifyListeners();
      });
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _loadQueueFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_uploadQueueKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    _queue.clear();
    for (final item in decoded) {
      if (item is int) {
        _queue.add(item);
        _phraseUploadStatus[item] = UploadStatus.queued;
      }
    }

    if (_queue.isNotEmpty && _uploadStatus == UploadStatus.notStarted) {
      _uploadStatus = UploadStatus.queued;
    }
    notifyListeners();
  }

  Future<void> _persistQueueToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uploadQueueKey, jsonEncode(_queue.toList()));
  }

  void _scheduleRetryLoop() {
    _retryTimer?.cancel();
    if (_queue.isEmpty) return;
    _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(processQueue());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
