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
import 'phrase_view.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../repos/phrases_repository.dart';
import '../repos/phrase.dart';
import '../ui/core/themes/colors.dart';
import 'upload_status.dart';

class TrainModeView extends StatelessWidget {
  final int index;
  final Key pageStorageKey;
  final List<Phrase> phrases;
  final void Function()? record;
  final void Function()? play;
  final void Function()? nextPhrase;
  final void Function()? previousPhrase;
  final bool isRecording;
  final bool isPlaying;
  final bool isRecorded;
  final UploadStatus uploadStatus;
  final PageController? controller;

  const TrainModeView(
      {super.key,
      required this.pageStorageKey,
      required this.index,
      required this.phrases,
      required this.nextPhrase,
      required this.previousPhrase,
      required this.record,
      required this.play,
      required this.isRecording,
      required this.isPlaying,
      required this.isRecorded,
      required this.uploadStatus,
      this.controller});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isLandscape = width > height;

    return OrientationBuilder(builder: (context, orientation) {
      // ── Controls (nav + record) ─────────────────────────────────
      final controls = Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                    label: AppLocalizations.of(context)!.previousPhraseButton,
                    hint: AppLocalizations.of(context)!.previousPhraseButtonHint,
                    child: IconButton.outlined(
                      onPressed: previousPhrase,
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous),
                    )),
                const SizedBox(width: 16),
                Semantics(
                    label: AppLocalizations.of(context)!.playPhraseButton,
                    hint: AppLocalizations.of(context)!.playPhraseButtonHint,
                    child: IconButton.outlined(
                      onPressed: play,
                      iconSize: 36,
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    )),
                const SizedBox(width: 16),
                Semantics(
                    label: AppLocalizations.of(context)!.nextPhraseButton,
                    hint: AppLocalizations.of(context)!.nextPhraseButtonHint,
                    child: IconButton.outlined(
                      onPressed: nextPhrase,
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: record,
                style: FilledButton.styleFrom(
                  backgroundColor: isRecording
                      ? AppColors.secondary
                      : (isRecorded
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                icon: Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  isRecording
                      ? AppLocalizations.of(context)!.stopRecordingButtonTitle
                      : (isRecorded
                          ? AppLocalizations.of(context)!.reRecordButtonTitle
                          : AppLocalizations.of(context)!.recordButtonTitle),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      // ── PageView ────────────────────────────────────────────────
      final pageView = PageView.builder(
        key: pageStorageKey,
        controller: controller,
        itemBuilder: (context, index) => PhraseView(phrase: phrases[index]),
        itemCount: phrases.length,
        onPageChanged: (index) =>
            Provider.of<PhrasesRepository>(context, listen: false)
                .jumpToPhrase(updatedPhraseIndex: index),
      );

      if (isLandscape) {
        return Row(children: [
          SizedBox(
            width: (width * 2 / 3) - 100,
            child: pageView,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [controls],
              ),
            ),
          ),
        ]);
      }

      // Portrait: phrase card expands to fill available space
      return Column(
        children: [
          Expanded(child: pageView),
          controls,
        ],
      );
    });
  }
}
