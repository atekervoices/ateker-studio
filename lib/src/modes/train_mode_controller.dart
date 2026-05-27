// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/audio_player.dart';
import '../repos/audio_recorder.dart';
import '../repos/phrase.dart';
import '../repos/phrases_repository.dart';
import '../repos/settings_repository.dart';

import '../repos/uploader.dart';
import '../ui/core/widgets/standard_app_bar.dart';
import 'train_mode_view.dart';
import 'upload_status.dart';

class TrainModeController extends StatefulWidget {
  const TrainModeController({super.key});

  @override
  State<TrainModeController> createState() => _TrainModeControllerState();
}

class _TrainModeControllerState extends State<TrainModeController> {
  var _uploadStatus = UploadStatus.notStarted;
  final Key _key = GlobalKey();
  final _pageController = PageController(initialPage: 0, viewportFraction: 0.8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      Provider.of<PhrasesRepository>(context, listen: false)
          .getLastRecordedPhraseIndex()
          .then((lastRecordedPhraseIndex) {
                if (!mounted) return;
                setState(() {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(lastRecordedPhraseIndex);
                  }
                });
              });
    });
  }

  void _previousPhrase() async {
    var phrasesRepoProvider =
        Provider.of<PhrasesRepository>(context, listen: false);
    phrasesRepoProvider.moveToPreviousPhrase();
    setState(() {
      _pageController.animateToPage(phrasesRepoProvider.currentPhraseIndex,
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
      _uploadStatus = UploadStatus.notStarted;
    });
  }

  void _nextPhrase() async {
    var phrasesRepoProvider =
        Provider.of<PhrasesRepository>(context, listen: false);
    phrasesRepoProvider.moveToNextPhrase();
    setState(() {
      _pageController.animateToPage(phrasesRepoProvider.currentPhraseIndex,
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
      _uploadStatus = UploadStatus.notStarted;
    });
  }

  Future<void> _deleteRecording(Phrase phrase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text(
            'This will delete the local copy so you can re-record. Your previously uploaded recording is preserved in the cloud.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await phrase.deleteRecording();
    if (!mounted) return;
    Provider.of<PhrasesRepository>(context, listen: false)
        .unmarkRecorded(phrase.index);
    Provider.of<AudioPlayer>(context, listen: false).load(audioPath: null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording deleted')),
    );
  }

  void _stopRecordingAndUpload(
      AudioRecorder recorder, Phrase phrase, AudioPlayer player) async {
    if (!recorder.isRecording) {
      recorder.start();
      return;
    }
    await recorder.stop();
    if (!mounted) return;
    final phrasesRepo = Provider.of<PhrasesRepository>(context, listen: false);
    final wasAlreadyRecorded = phrasesRepo.isRecorded(phrase.index);
    phrasesRepo.markRecorded(phrase.index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAlreadyRecorded ? 'Re-recording saved' : 'Recording saved',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Provider.of<Uploader>(context, listen: false).enqueuePhrase(phrase);
    if (!mounted) return;
    if (Provider.of<SettingsRepository>(context, listen: false).autoAdvance) {
      _nextPhrase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<PhrasesRepository, AudioPlayer, AudioRecorder>(
        builder: (_, repo, player, recorder, __) {
      if (repo.phrases.isEmpty) {
        return Scaffold(
          appBar: buildStandardAppBar(
            context: context,
            title: 'Speech',
            subtitle: 'Read the prompt aloud',
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: buildStandardAppBar(
          context: context,
          title: 'Speech',
          subtitle: 'Read the prompt aloud',
          actions: [

            if (player.canPlay)
              IconButton(
                tooltip: 'Delete recording',
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: repo.currentPhrase == null
                    ? null
                    : () => _deleteRecording(repo.currentPhrase!),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${repo.currentPhraseIndex + 1} / ${repo.phrases.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: TrainModeView(
          index: repo.currentPhraseIndex,
          pageStorageKey: _key,
          phrases: repo.phrases,
          previousPhrase: repo.currentPhraseIndex == 0 ? null : _previousPhrase,
          nextPhrase: repo.currentPhraseIndex == repo.phrases.length - 1
              ? null
              : _nextPhrase,
          record: player.isPlaying
              ? null
              : () {
                  _stopRecordingAndUpload(recorder, repo.currentPhrase!, player);
                },
          isRecording: recorder.isRecording,
          play: player.canPlay && !recorder.isRecording
              ? (player.isPlaying ? player.pause : player.play)
              : null,
          isPlaying: player.isPlaying,
          isRecorded: player.canPlay,
          uploadStatus: _uploadStatus,
          controller: _pageController,
        ),
      );
    });
  }
}
