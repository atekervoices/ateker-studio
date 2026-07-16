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

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_prompt.dart';
import '../repos/admin_prompts_repository.dart';

/// Parses CSV string into rows and columns handling quotes, commas, and newlines.
List<List<String>> parseCsv(String csvText) {
  final List<List<String>> result = [];
  final List<String> currentRow = [];
  final StringBuffer fieldBuffer = StringBuffer();
  bool inQuotes = false;
  int i = 0;

  while (i < csvText.length) {
    final char = csvText[i];

    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < csvText.length && csvText[i + 1] == '"') {
          // Double quote inside quotes means a single quote character
          fieldBuffer.write('"');
          i += 2;
          continue;
        } else {
          // Closing quote
          inQuotes = false;
          i++;
          continue;
        }
      } else {
        fieldBuffer.write(char);
        i++;
      }
    } else {
      if (char == '"') {
        inQuotes = true;
        i++;
      } else if (char == ',') {
        currentRow.add(fieldBuffer.toString().trim());
        fieldBuffer.clear();
        i++;
      } else if (char == '\r' || char == '\n') {
        currentRow.add(fieldBuffer.toString().trim());
        fieldBuffer.clear();
        
        // Only add row if it contains some data
        if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow[0].isNotEmpty)) {
          result.add(List.from(currentRow));
        }
        currentRow.clear();

        // Handle CRLF line ending
        if (char == '\r' && i + 1 < csvText.length && csvText[i + 1] == '\n') {
          i += 2;
        } else {
          i++;
        }
      } else {
        fieldBuffer.write(char);
        i++;
      }
    }
  }

  // Add the last field and row if any
  if (fieldBuffer.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(fieldBuffer.toString().trim());
    if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow[0].isNotEmpty)) {
      result.add(currentRow);
    }
  }

  return result;
}

class CsvBulkUploadDialog extends StatefulWidget {
  const CsvBulkUploadDialog({super.key});

  @override
  State<CsvBulkUploadDialog> createState() => _CsvBulkUploadDialogState();
}

class _CsvBulkUploadDialogState extends State<CsvBulkUploadDialog> {
  bool _isParsing = false;
  bool _isUploading = false;
  String? _fileName;
  
  List<AdminPromptItem> _validPrompts = [];
  List<String> _validationErrors = [];
  
  static const _atekerOrange = Color(0xFFD06E1A);

  Future<void> _pickAndParseCsv() async {
    setState(() {
      _isParsing = true;
      _validPrompts.clear();
      _validationErrors.clear();
      _fileName = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isParsing = false);
        return;
      }

      final file = result.files.first;
      _fileName = file.name;

      if (file.bytes == null) {
        throw Exception('Could not read file contents.');
      }

      // Decode bytes to string
      String csvText;
      try {
        csvText = utf8.decode(file.bytes!);
      } catch (_) {
        // Fallback to Latin-1 if UTF-8 fails
        csvText = latin1.decode(file.bytes!);
      }

      final parsedData = parseCsv(csvText);

      if (parsedData.isEmpty) {
        setState(() {
          _validationErrors.add('The CSV file is empty.');
          _isParsing = false;
        });
        return;
      }

      final headers = parsedData.first;
      
      // Determine index of expected columns
      int textIdx = headers.indexWhere((h) => 
          h.toLowerCase() == 'text' || 
          h.toLowerCase() == 'prompt' || 
          h.toLowerCase() == 'phrase');
          
      int topicIdx = headers.indexWhere((h) => 
          h.toLowerCase() == 'topic' || 
          h.toLowerCase() == 'category');
          
      int kindIdx = headers.indexWhere((h) => 
          h.toLowerCase() == 'kind' || 
          h.toLowerCase() == 'type');
          
      int imageUrlIdx = headers.indexWhere((h) => 
          h.toLowerCase() == 'imageurl' || 
          h.toLowerCase() == 'image_url' || 
          h.toLowerCase() == 'image' || 
          h.toLowerCase() == 'url');

      if (textIdx == -1 || topicIdx == -1) {
        setState(() {
          _validationErrors.add(
            'Required column headers not found. Your CSV must have at least "text" and "topic" columns.'
          );
          _isParsing = false;
        });
        return;
      }

      final tempValid = <AdminPromptItem>[];
      final tempErrors = <String>[];

      for (int i = 1; i < parsedData.length; i++) {
        final row = parsedData[i];
        final rowNum = i + 1; // 1-indexed line number in CSV (accounting for header)

        if (row.isEmpty || (row.length == 1 && row[0].isEmpty)) {
          continue; // Skip empty rows silently
        }

        // Ensure row has enough elements for text and topic
        final maxIndexNeeded = textIdx > topicIdx ? textIdx : topicIdx;
        if (row.length <= maxIndexNeeded) {
          tempErrors.add('Row $rowNum: Missing required columns (text or topic).');
          continue;
        }

        final text = row[textIdx].trim();
        final topicStr = row[topicIdx].trim().toLowerCase();
        
        // Parse kind (default to text)
        String kind = 'text';
        if (kindIdx != -1 && row.length > kindIdx) {
          final kindStr = row[kindIdx].trim().toLowerCase();
          if (kindStr.isNotEmpty) {
            if (kindStr == 'text' || kindStr == 'image') {
              kind = kindStr;
            } else {
              tempErrors.add('Row $rowNum: Invalid kind "$kindStr" (must be "text" or "image").');
              continue;
            }
          }
        }

        // Validate text
        if (text.isEmpty) {
          tempErrors.add('Row $rowNum: Prompt text cannot be empty.');
          continue;
        }

        // Validate topic
        ImagePromptTopic? topic;
        for (final value in ImagePromptTopic.values) {
          if (value.name.toLowerCase() == topicStr || 
              value.displayName.toLowerCase() == topicStr) {
            topic = value;
            break;
          }
        }

        if (topic == null) {
          final allowedTopics = ImagePromptTopic.values.map((v) => v.name).join(', ');
          tempErrors.add('Row $rowNum: Invalid topic "$topicStr" (must be one of: $allowedTopics).');
          continue;
        }

        // Parse imageUrl (optional)
        String? imageUrl;
        if (imageUrlIdx != -1 && row.length > imageUrlIdx) {
          final urlStr = row[imageUrlIdx].trim();
          if (urlStr.isNotEmpty) {
            imageUrl = urlStr;
          }
        }

        // Image validation
        if (kind == 'image' && (imageUrl == null || imageUrl.isEmpty)) {
          tempErrors.add('Row $rowNum: Spontaneous image prompts require a valid imageUrl.');
          continue;
        }

        // All good! Build prompt item
        tempValid.add(
          AdminPromptItem(
            id: '',
            kind: kind,
            text: text,
            topic: topic,
            imageUrl: imageUrl,
            imageFileName: imageUrl != null && imageUrl.isNotEmpty
                ? imageUrl.split('/').last.split('?').first
                : '',
            createdAt: DateTime.now(),
            createdBy: '', // Filled in by repository
          ),
        );
      }

      setState(() {
        _validPrompts = tempValid;
        _validationErrors = tempErrors;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _validationErrors.add('Error reading file: $e');
        _isParsing = false;
      });
    }
  }

  Future<void> _uploadPrompts() async {
    if (_validPrompts.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final repository = context.read<AdminPromptsRepository>();
      await repository.addPromptsBatch(_validPrompts);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded ${_validPrompts.length} prompts!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading prompts: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _fileName != null;
    final dialogWidth = MediaQuery.of(context).size.width * 0.55;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _atekerOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: _atekerOrange,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Bulk Upload Prompts (CSV)',
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth < 500 ? 500 : dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasData && !_isParsing) ...[
                const Text(
                  'Upload prompts using a CSV spreadsheet. You can import both Read Speech (text) and Spontaneous Speech (image-based) prompts in bulk.',
                  style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                _buildTemplateGuide(),
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _pickAndParseCsv,
                    icon: const Icon(Icons.file_open_rounded),
                    label: const Text('Choose CSV File'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              ] else if (_isParsing) ...[
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _atekerOrange),
                        SizedBox(height: 16),
                        Text(
                          'Parsing CSV file and validating format...',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                _buildFileSummaryHeader(),
                const SizedBox(height: 16),
                if (_validPrompts.isNotEmpty) _buildValidSection(),
                if (_validationErrors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildErrorsSection(),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
        ),
        if (hasData && ! _isParsing && _validPrompts.isNotEmpty)
          FilledButton.icon(
            onPressed: _isUploading ? null : _uploadPrompts,
            icon: _isUploading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: Text('Upload ${_validPrompts.length} Prompts'),
            style: FilledButton.styleFrom(
              backgroundColor: _atekerOrange,
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expected CSV Structure:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Columns must include headers (case-insensitive):',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          const BulletPoint(text: 'text: The prompt text shown to contributors.'),
          const BulletPoint(text: 'topic: Category (animals, food, nature, objects, people).'),
          const BulletPoint(text: 'kind: "text" for speech reading, "image" for spontaneous speech.'),
          const BulletPoint(text: 'imageUrl: Storage or web URL (required for image prompts).'),
          const SizedBox(height: 12),
          const Text(
            'Example CSV Rows:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SelectableText(
              'text,topic,kind,imageUrl\n'
              '"Ejok konyen a ekon ekes.","nature","text",\n'
              '"Describe this livestock field","animals","image","https://example.com/field.jpg"',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF38BDF8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _fileName ?? 'Selected File',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _pickAndParseCsv,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Change File', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildValidSection() {
    final textCount = _validPrompts.where((p) => p.kind == 'text').length;
    final imageCount = _validPrompts.where((p) => p.kind == 'image').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Ready to Import (${_validPrompts.length} Prompts)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• $textCount Read Speech (text) prompts\n• $imageCount Spontaneous Speech (image-based) prompts',
            style: const TextStyle(color: Color(0xFF047857), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                'Validation Errors (${_validationErrors.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'These rows contain errors and will be skipped during upload:',
            style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _validationErrors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          _validationErrors[index],
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.black54, fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 11))),
        ],
      ),
    );
  }
}
