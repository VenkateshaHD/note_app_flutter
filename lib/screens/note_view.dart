import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:note_app/common.dart';
import 'package:note_app/screens/notes.dart';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

// For URL launching - add to pubspec.yaml: url_launcher: ^6.1.12
// import 'package:url_launcher/url_launcher.dart';

class NoteViewScreen extends StatefulWidget {
  final String noteId;
  final String title;
  final String content;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String? attachmentUrl;
  final String? attachmentType;

  const NoteViewScreen({
    Key? key,
    required this.noteId,
    required this.title,
    required this.content,
    required this.createdDate,
    required this.updatedDate,
    this.attachmentUrl,
    this.attachmentType,
  }) : super(key: key);

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  bool _isLoading = false;

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _openAttachment() async {
    if (widget.attachmentUrl == null) return;

    // setState(() {
    //   _isLoading = true;
    // });

    try {
      final Uri url = Uri.parse("https://flutter.dev");
      //  final Uri url = Uri.parse(note.attachmentName);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        ); // opens in browser
      } else {
        throw 'Could not launch $url';
      }

      // For demo purposes, show a snackbar
      await Future.delayed(const Duration(milliseconds: 500));

      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text(
      //           'Opening ${widget.attachmentType}: ${widget.attachmentUrl}',
      //         ),
      //         duration: const Duration(seconds: 3),
      //         action: SnackBarAction(
      //           label: 'Copy Link',
      //           onPressed: () {
      //             Clipboard.setData(ClipboardData(text: widget.attachmentUrl!));
      //             ScaffoldMessenger.of(context).showSnackBar(
      //               const SnackBar(
      //                 content: Text('Link copied to clipboard'),
      //                 duration: Duration(seconds: 2),
      //               ),
      //             );
      //           },
      //         ),
      //       ),
      //     );
      //   }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening attachment: $e'),
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

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editNote() {
    // Navigate to edit screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit note functionality')));
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteNotes();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void deleteNotes() async {
    final storage = const FlutterSecureStorage();

    String userId = await storage.read(key: 'user_id') ?? '';
    String token = await storage.read(key: 'token') ?? '';

    String url = '$serverAPI/notes/delete/${widget.noteId}';

    var response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": 'Bearer $token'},
    );

    var responseBody = json.decode(response.body);
    print(responseBody);

    if (response.statusCode == 200 &&
        responseBody["status"].toString() != '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NotesCloudDashboard()),
        (route) => false,
      );
    } else  {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
          duration: Duration(seconds: 2),
        ),
      );
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        title: const Text(
          'Back to Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editNote();
                  break;
                case 'copy':
                  _copyContent();
                  break;
                case 'delete':
                  _deleteNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              // const PopupMenuItem(
              //   value: 'edit',
              //   child: Row(
              //     children: [
              //       Icon(Icons.edit, size: 18, color: Color(0xFF6B7280)),
              //       SizedBox(width: 8),
              //       Text('Edit Note'),
              //     ],
              //   ),
              // ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 18, color: Color(0xFF6B7280)),
                    SizedBox(width: 8),
                    Text('Copy Content'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Note', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Date information
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  'Created: ${_formatDate(widget.createdDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  'Updated: ${_formatDate(widget.updatedDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Content card
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
                  // Content
                  SelectableText(
                    widget.content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),

                  // CloudFront Link Widget
                  if (widget.attachmentUrl != null) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),

                    // Attachment section header
                    const Text(
                      'Attachment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CloudFront link widget
                    GestureDetector(
                      onTap: _isLoading ? null : _openAttachment,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4A90E2).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // File type icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                widget.attachmentType?.toUpperCase() == 'PDF'
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: const Color(0xFF4A90E2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // File info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.attachmentUrl!
                                                .split('/')
                                                .last
                                                .length >
                                            30
                                        ? '${widget.attachmentUrl!.split('/').last.substring(0, 30)}...'
                                        : widget.attachmentUrl!.split('/').last,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.attachmentUrl!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Loading indicator or open icon
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4A90E2),
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.open_in_new,
                                color: Color(0xFF4A90E2),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // File type badge
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.attachmentType?.toUpperCase() ?? 'FILE',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A90E2),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Click to open in browser',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage and navigation helper
class NoteViewHelper {
  static Future<bool?> viewNote(
    BuildContext context, {
    required String noteId,
    required String title,
    required String content,
    required DateTime createdDate,
    required DateTime updatedDate,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => NoteViewScreen(
          noteId: noteId,
          title: title,
          content: content,
          createdDate: createdDate,
          updatedDate: updatedDate,
          attachmentUrl: attachmentUrl,
          attachmentType: attachmentType,
        ),
      ),
    );
  }
}

// Example of how to call this from your notes list:
/*
// In your notes list, when a note is tapped:
await NoteViewHelper.viewNote(
  context,
  noteId: note.id,
  title: 'Java Operator',
  content: '''public class Main {
public static void main(String[] args) {
int sum1 = 100 + 50;
int sum2 = sum1 + 250;
int sum3 = sum2 + sum2;
System.out.println(sum1);
System.out.println(sum2);
System.out.println(sum3);
}
}''',
  createdDate: DateTime(2025, 7, 29, 9, 43),
  updatedDate: DateTime(2025, 7, 29, 9, 43),
  attachmentUrl: 'https://dhfeh4cz70vvz.cloudfront.net/documents/java_operator_guide.pdf',
  attachmentType: 'PDF',
);
*/
