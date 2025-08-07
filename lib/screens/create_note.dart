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

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({Key? key}) : super(key: key);

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  Uint8List? _fileBytes;
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // final result = await FilePicker.platform.pickFiles();

    // if (result != null && result.files.single.path != null) {
    //   setState(() => _selectedFile = File(result.files.single.path!));
    // }
    // // Simulate file picker - in real app use file_picker package
    // setState(() {
    //   _fileName = _selectedFile!.path.split('/').last;
    // });

    final result = await FilePicker.platform.pickFiles(
      withData: true, // Required for web
    );

    if (result != null) {
      if (kIsWeb) {
        // Web: Use bytes
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
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

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  Future<void> _saveNote() async {
    final storage = const FlutterSecureStorage();

    String token = await storage.read(key: "token") ?? "";

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Map<String, String> data = {
        "title": _titleController.text,
        "content": _contentController.text,
        "isPublic": "true", // or "false"
      };

      String url = '$serverAPI/notes/add';

      var request = http.MultipartRequest('Post', Uri.parse(url));

      request.fields.addAll(data);
      request.headers['Authorization'] = 'Bearer $token';

      // if (_selectedFile != null) {
      //   request.files.add(
      //     await http.MultipartFile.fromPath('files', _selectedFile!.path),
      //   );
      // }

       // File field
    if (kIsWeb) {
      if (_fileBytes != null && _fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          _fileBytes!,
          filename: _fileName!,
        ));
      }
    } else {
      if (_selectedFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'files',
          _selectedFile!.path,
        ));
      }
    }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(response.body);

      setState(() {
        _isLoading = false;
      });

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    }
  }

  void _cancel() {
    // Show confirmation dialog if there's unsaved content
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Keep editing',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close create note screen
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _cancel,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        title: const Text(
          'Create New Note',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
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

                          // File Attachment section
                          const Text(
                            'File Attachment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_fileName == null) ...[
                            // Upload button
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
                                      'Upload File',
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
                            const SizedBox(height: 8),
                            const Text(
                              'PDF only (single file)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ] else ...[
                            // File selected
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.picture_as_pdf,
                                    color: Color(0xFF4A90E2),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _fileName!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF374151),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _removeFile,
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
                      onPressed: _isLoading ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: const Color(0xFF9CA3AF),
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
                                Icon(Icons.save, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Note',
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
    );
  }
}

// Example of how to navigate to this screen from the dashboard
class NavigationHelper {
  static Future<bool?> createNewNote(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CreateNoteScreen()),
    );
  }
}
