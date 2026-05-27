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

import '../generated/l10n/app_localizations.dart';
import '../ui/core/themes/colors.dart';

enum UploadStatus { notStarted, started, completed, interrupted }

class TranscribeModeView extends StatelessWidget {
  final String phrase;
  final String transcriptUrl;
  final void Function()? record;
  final void Function()? play;
  final bool isRecording;
  final bool isPlaying;
  final bool isRecorded;
  final UploadStatus uploadStatus;

  const TranscribeModeView({
    super.key,
    required this.phrase,
    required this.transcriptUrl,
    required this.record,
    required this.play,
    required this.isRecording,
    required this.isPlaying,
    required this.isRecorded,
    required this.uploadStatus,
  });

  bool get _showUploadProgress {
    switch (uploadStatus) {
      case UploadStatus.notStarted:
        return false;
      case UploadStatus.started:
        return true;
      case UploadStatus.completed:
        return false;
      case UploadStatus.interrupted:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var sideLength = width;
    if (height < width) {
      sideLength = height - 180;
    }
    return OrientationBuilder(builder: (context, orientation) {
      final List<Widget> firstHalf = [
        SizedBox(
            width: orientation == Orientation.landscape
                ? (width * 2 / 3) - 100
                : sideLength,
            height: sideLength,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  orientation == Orientation.landscape ? 48 : 24, 24, 24, 16),
              child: SizedBox(
                width: MediaQuery.of(context).size.height,
                height: MediaQuery.of(context).size.height - 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transcriptUrl == ''
                        ? AppLocalizations.of(context)!
                            .addTranscriptionEndpointPrompt
                        : AppLocalizations.of(context)!
                            .transcriptionEndpointDisplay(transcriptUrl)),
                    Visibility(
                      visible: _showUploadProgress,
                      child: const CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical, //.horizontal
                        child: Text(
                          phrase,
                          style: const TextStyle(fontSize: 24),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ];
      final List<Widget> secondHalf = [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton.outlined(
                onPressed: play,
                iconSize: 70,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MaterialButton(
                  onPressed: record,
                  color: isRecording
                      ? AppColors.secondary
                      : (isRecorded
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary),
                  textColor: Colors.white,
                  disabledColor: Colors.grey,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(80)),
                  ),
                  padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
                  child: Text(
                    isRecording
                        ? AppLocalizations.of(context)!
                            .stopTranscribingButtonTitle
                        : AppLocalizations.of(context)!.transcribeButtonTitle,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        )
      ];

      return orientation == Orientation.portrait
          ? Column(children: firstHalf + secondHalf)
          : Row(children: [
              Column(children: firstHalf),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      child: Column(children: secondHalf)))
            ]);
    });
  }
}
