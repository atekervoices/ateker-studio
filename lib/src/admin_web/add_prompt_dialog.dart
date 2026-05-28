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

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_prompt.dart';
import '../repos/admin_prompts_repository.dart';

class AddPromptDialog extends StatefulWidget {
  final AdminPromptItem? promptToEdit;
  final String? initialKind;

  const AddPromptDialog({super.key, this.promptToEdit, this.initialKind});

  @override
  State<AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends State<AddPromptDialog> {
  late TextEditingController _promptController;
  late ImagePromptTopic _selectedTopic;
  late String _selectedKind; // 'text' or 'image'
  Uint8List? _selectedImageData;
  String? _selectedImageFileName;
  bool _isLoading = false;
  String? _imagePreviewUrl;

  static const _atekerOrange = Color(0xFFD06E1A);

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: widget.promptToEdit?.text ?? '',
    );
    _selectedTopic = widget.promptToEdit?.topic ?? ImagePromptTopic.objects;
    _selectedKind = widget.promptToEdit?.kind ??
        widget.initialKind ??
        'text';
    _selectedImageFileName = widget.promptToEdit?.imageFileName;
    _imagePreviewUrl = widget.promptToEdit?.imageUrl;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promptToEdit != null;
    final isImageKind = _selectedKind == 'image';

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _atekerOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add_circle_outline,
              color: _atekerOrange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Prompt' : 'Add New Prompt',
            style: const TextStyle(color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Prompt Kind Selector ──
              const Text(
                'Prompt Type',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KindToggleButton(
                      icon: Icons.text_snippet_outlined,
                      label: 'Read Speech',
                      subtitle: 'Text to read aloud',
                      isSelected: _selectedKind == 'text',
                      onTap: () => setState(() => _selectedKind = 'text'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KindToggleButton(
                      icon: Icons.image_outlined,
                      label: 'Spontaneous',
                      subtitle: 'Image to describe',
                      isSelected: _selectedKind == 'image',
                      onTap: () => setState(() => _selectedKind = 'image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Prompt Text ──
              const Text(
                'Prompt Text',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _promptController,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: isImageKind
                      ? 'Describe what the image shows (optional guidance)'
                      : 'Enter the text for contributors to read aloud',
                  hintStyle: const TextStyle(color: Colors.white30),
                ),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 20),

              // ── Topic Category ──
              const Text(
                'Topic Category',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ImagePromptTopic>(
                initialValue: _selectedTopic,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF1E293B)),
                items: ImagePromptTopic.values.map((topic) {
                  return DropdownMenuItem(
                    value: topic,
                    child: Text(topic.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTopic = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── Image Upload (only for Spontaneous Speech / image kind) ──
              if (isImageKind) ...[
                const Text(
                  'Image Upload',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildImageUploadSection(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Save Changes' : 'Add Prompt'),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    // Show image preview if we have one
    if (_selectedImageData != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImageData!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedImageFileName ?? 'image',
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Change Image'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _selectedImageData = null;
                          _selectedImageFileName = null;
                          _imagePreviewUrl = null;
                        });
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      );
    }

    // Show existing image URL preview (editing)
    if (_imagePreviewUrl != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imagePreviewUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white24, size: 40),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Replace Image'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _imagePreviewUrl = null;
                        });
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      );
    }

    // Empty state: show upload area
    return InkWell(
      onTap: _isLoading ? null : _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _atekerOrange.withValues(alpha: 0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _atekerOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: _atekerOrange, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'Click to upload an image',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'JPG, PNG or WebP • Max 10 MB',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedImageData = file.bytes;
            _selectedImageFileName = file.name;
            _imagePreviewUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a prompt text'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Image is required only for 'image' kind
    if (_selectedKind == 'image' &&
        _selectedImageData == null &&
        _imagePreviewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image for spontaneous speech prompts'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = context.read<AdminPromptsRepository>();

      if (widget.promptToEdit == null) {
        // Add new prompt
        await repository.addPrompt(
          kind: _selectedKind,
          text: _promptController.text,
          topic: _selectedTopic,
          imageData: _selectedImageData,
          imageFileName: _selectedImageFileName ??
              'prompt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else {
        // Edit existing prompt
        await repository.updatePrompt(
          promptId: widget.promptToEdit!.id,
          kind: _selectedKind,
          text: _promptController.text,
          topic: _selectedTopic,
          imageData: _selectedImageData,
          imageFileName: _selectedImageFileName ??
              widget.promptToEdit!.imageFileName,
          existingImageUrl: _imagePreviewUrl ?? widget.promptToEdit!.imageUrl,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ── Kind Toggle Button Widget ───────────────────────────────────────────────

class _KindToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _KindToggleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  static const _atekerOrange = Color(0xFFD06E1A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _atekerOrange.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _atekerOrange
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? _atekerOrange : Colors.black,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF1E293B) : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
