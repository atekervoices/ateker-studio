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

import '../repos/phrase.dart';
import '../repos/uploader.dart';
import 'upload_status.dart';

final class PhraseView extends StatelessWidget {
  final Phrase _phrase;

  const PhraseView({super.key, required Phrase phrase}) : _phrase = phrase;

  @override
  Widget build(BuildContext context) {
    final uploader = Provider.of<Uploader>(context, listen: true);
    final uploadStatus = uploader.statusForPhrase(_phrase.index);
    return FutureBuilder<bool>(
        future: _phrase.isRecordingAvailableLocally,
        builder: (context, snapshot) {
          var isRecordingAvailable = (snapshot.data == true);
          return OrientationBuilder(builder: (context, orientation) {
            return Card(
              margin: EdgeInsets.symmetric(
                  vertical: orientation == Orientation.portrait ? 48 : 0,
                  horizontal: 6),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(48)),
              ),
              color: isRecordingAvailable
                  ? ColorScheme.of(context).onTertiary
                  : ColorScheme.of(context).onSecondary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${_phrase.index}',
                              style: TextStyle(
                                  color: ColorScheme.of(context).outline),
                            ),
                          ),
                        ),
                        Icon(
                          switch (uploadStatus) {
                            UploadStatus.completed => Icons.cloud_done,
                            UploadStatus.started => Icons.cloud_upload,
                            UploadStatus.queued => Icons.cloud_queue,
                            UploadStatus.interrupted => Icons.cloud_off,
                            _ => Icons.cloud_upload,
                          },
                          color: switch (uploadStatus) {
                            UploadStatus.completed => Colors.green,
                            UploadStatus.interrupted => Colors.red,
                            UploadStatus.started => Theme.of(context)
                                .colorScheme
                                .primary,
                            UploadStatus.queued => Theme.of(context)
                                .colorScheme
                                .secondary,
                            _ => Colors.transparent,
                          },
                        ),
                        Container(
                          decoration: ShapeDecoration(
                            shape: const CircleBorder(),
                            color: !isRecordingAvailable
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.primary,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.check_rounded,
                            color: !isRecordingAvailable
                                ? Colors.transparent
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _phrase.text,
                          style: TextTheme.of(context).headlineMedium?.copyWith(
                              color: isRecordingAvailable
                                  ? ColorScheme.of(context).tertiary
                                  : ColorScheme.of(context).secondary),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }
}
