import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:note_app/common.dart';

class UpdateNoteScreen extends StatefulWidget {
  final String noteId;
  final String initialTitle;
  final String initialContent;
  final String? existingAttachmentUrl;
  final String? existingAttachmentType;

  const UpdateNoteScreen({
    Key? key,
    required this.noteId,
    required this.initialTitle,
    required this.initialContent,
    this.existingAttachmentUrl,
    this.existingAttachmentType,
  }) : super(key: key);

  @override
  State<UpdateNoteScreen> createState() => _UpdateNoteScreenState();
}

class _UpdateNoteScreenState extends State<UpdateNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  // File handling
  Uint8List? _fileBytes;
  File? _selectedFile;
  String? _fileName;
  String? _existingAttachmentUrl;
  String? _existingAttachmentType;
  bool _removeExistingAttachment = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _titleController.text = widget.initialTitle;
    _contentController.text = widget.initialContent;
    _existingAttachmentUrl = widget.existingAttachmentUrl;
    _existingAttachmentType = widget.existingAttachmentType;

    // Add listeners to track changes
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final hasTextChanges =
        _titleController.text != widget.initialTitle ||
        _contentController.text != widget.initialContent;
    final hasFileChanges = (_selectedFile != null || _fileBytes != null) || _removeExistingAttachment;

    if (mounted) {
      setState(() {
        _hasChanges = hasTextChanges || hasFileChanges;
      });
    }
  }

  Future<void> _pickFile() async {
    // Simulate file picker - in real app use file_picker package
    // setState(() {
    //   _fileName = 'updated_document.pdf';
    //   _selectedFile = File('path/to/updated_document.pdf'); // Simulated
    //   _hasChanges = true;
    // });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('New file selected: updated_document.pdf'),
    //     duration: Duration(seconds: 2),
    //   ),
    // );

    final result = await FilePicker.platform.pickFiles(
      withData: true, // Required for web
    );

    if (result != null) {
      if (kIsWeb) {
        // Web: Use bytes
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _hasChanges = true;
        });
      } else {
        // Mobile: Use path
        setState(() {
          final path = result.files.single.path!;
          _selectedFile = io.File(path);
          _fileName = path.split('/').last;
        });
      }
    }
  }

  void _removeNewFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _onContentChanged();
    });
  }

  void _removeExistingFile() {
    setState(() {
      _removeExistingAttachment = true;
      _hasChanges = true;
    });
  }

  void _restoreExistingFile() {
    setState(() {
      _removeExistingAttachment = false;
      _onContentChanged();
    });
  }

  Future<void> _updateNote() async {
    final storage = const FlutterSecureStorage();

    String token = await storage.read(key: "token") ?? "";

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate API call to update note
        // await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Map<String, String> data = {
            "title": _titleController.text,
            "content": _contentController.text,
            "isPublic": "true", // or "false"
          };

          String url = '$serverAPI/notes/update/${widget.noteId}';

          var request = http.MultipartRequest('Post', Uri.parse(url));

          request.fields.addAll(data);
          request.headers['Authorization'] = 'Bearer $token';

          // File field
          if (kIsWeb) {
            if (_fileBytes != null && _fileName != null) {
              request.files.add(
                http.MultipartFile.fromBytes(
                  'files',
                  _fileBytes!,
                  filename: _fileName!,
                ),
              );
            }
          } else {
            if (_selectedFile != null) {
              request.files.add(
                await http.MultipartFile.fromPath('files', _selectedFile!.path),
              );
            }
          }
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);
          var responseBody = json.decode(response.body);
          print(response.body);
          if (response.statusCode == 200) {
            // throw Exception('Error updating note: ${response.statusCode} ${response.body}');
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Return updated data to previous screen
            Navigator.of(context).pop({
              'updated': true,
              'title': _titleController.text.trim(),
              'content': _contentController.text.trim(),
              'hasNewFile': _selectedFile != null,
              'fileName': _fileName,
              'removedAttachment': _removeExistingAttachment,
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseBody["detail"]),
                // backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating note: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _cancel() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(
                  context,
                ).pop({'updated': false}); // Close edit screen
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop({'updated': false});
    }
  }

  void _previewChanges() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Changes'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_titleController.text != widget.initialTitle) ...[
                const Text(
                  'Title:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Old: ${widget.initialTitle}',
                  style: TextStyle(color: Colors.red[600]),
                ),
                Text(
                  'New: ${_titleController.text}',
                  style: TextStyle(color: Colors.green[600]),
                ),
                const SizedBox(height: 16),
              ],
              if (_contentController.text != widget.initialContent) ...[
                const Text(
                  'Content changed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              if (_selectedFile != null || _fileBytes != null) ...[
                Text(
                  'New file: $_fileName',
                  style: TextStyle(color: Colors.green[600]),
                ),
                const SizedBox(height: 8),
              ],
              if (_removeExistingAttachment &&
                  _existingAttachmentUrl != null) ...[
                Text(
                  'Removing: ${_existingAttachmentUrl!.split('/').last}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _cancel();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          ),
          title: const Text(
            'Update Note',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _previewChanges,
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    color: Color(0xFF4A90E2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Changes indicator
              if (_hasChanges)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  color: const Color(0xFFFEF3C7),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'You have unsaved changes',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _previewChanges,
                        child: const Text(
                          'Preview',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Note Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title field
                            const Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '*',
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter note title',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4A90E2),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Content field
                            const Text(
                              'Content',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _contentController,
                              maxLines: 12,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter content';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your note content...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4A90E2),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // File Attachments section
                            const Text(
                              'File Attachments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Existing attachment
                            if (_existingAttachmentUrl != null &&
                                !_removeExistingAttachment) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF0EA5E9),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Color(0xFF0EA5E9),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Current attachment',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF0EA5E9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _existingAttachmentUrl!
                                                .split('/')
                                                .last,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _removeExistingFile,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Color(0xFF6B7280),
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Remove attachment',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Removed attachment indicator
                            if (_removeExistingAttachment &&
                                _existingAttachmentUrl != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Attachment will be removed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFEF4444),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _existingAttachmentUrl!
                                                .split('/')
                                                .last,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6B7280),
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _restoreExistingFile,
                                      child: const Text(
                                        'Undo',
                                        style: TextStyle(
                                          color: Color(0xFF4A90E2),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // New file selection
                            if (_selectedFile == null && _fileBytes == null) ...[
                              GestureDetector(
                                onTap: _pickFile,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        color: Color(0xFF4A90E2),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add New File',
                                        style: TextStyle(
                                          color: Color(0xFF4A90E2),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // New file selected
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF22C55E),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Color(0xFF22C55E),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'New file selected',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF22C55E),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _fileName!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _removeNewFile,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Color(0xFF6B7280),
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'PDF and images only (single file)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || !_hasChanges
                            ? null
                            : _updateNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasChanges
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF9CA3AF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.update, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Update Note',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation helper
class UpdateNoteHelper {
  static Future<Map<String, dynamic>?> updateNote(
    BuildContext context, {
    required String noteId,
    required String initialTitle,
    required String initialContent,
    String? existingAttachmentUrl,
    String? existingAttachmentType,
  }) {
    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => UpdateNoteScreen(
          noteId: noteId,
          initialTitle: initialTitle,
          initialContent: initialContent,
          existingAttachmentUrl: existingAttachmentUrl,
          existingAttachmentType: existingAttachmentType,
        ),
      ),
    );
  }
}

// Example usage:
/*
// From note view screen or notes list:
final result = await UpdateNoteHelper.updateNote(
  context,
  noteId: '1',
  initialTitle: 'Java Operator',
  initialContent: 'public class Main {...}',
  existingAttachmentUrl: 'https://dhfeh4cz70vvz.cloudfront.net/file.pdf',
  existingAttachmentType: 'PDF',
);

if (result != null && result['updated'] == true) {
  // Note was updated, refresh the UI
  print('Title: ${result['title']}');
  print('Content: ${result['content']}');
  print('Has new file: ${result['hasNewFile']}');
  print('Removed attachment: ${result['removedAttachment']}');
}
*/
