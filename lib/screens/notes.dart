import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:note_app/common.dart';
import 'package:note_app/screens/note_view.dart';
import 'package:url_launcher/url_launcher.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String attachmentName;
  final String attachmentType;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.attachmentName,
    required this.attachmentType,
  });
}

class NotesCloudDashboard extends StatefulWidget {
  const NotesCloudDashboard({Key? key}) : super(key: key);

  @override
  State<NotesCloudDashboard> createState() => _NotesCloudDashboardState();
}

class _NotesCloudDashboardState extends State<NotesCloudDashboard> {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    // _filteredNotes = _notes;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      loading = true;
    });
    await Future.delayed(Duration(seconds: 2));
    _filteredNotes = [];
    _notes = [];
    final storage = const FlutterSecureStorage();

    String token = await storage.read(key: 'token') ?? '';

    String url = '$serverAPI/notes/';

    var response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      responseBody.forEach((note) {
        _notes.add(
          Note(
            id: note["id"].toString(),
            title: note["title"],
            content: note["content"],
            date: DateTime.parse(note["created_at"]),
            attachmentName: note["file_url"] ?? '',
            attachmentType: "PDF",
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong")));
      loading = false;
      return;
    }
    _filteredNotes = _notes;
    loading = false;
    setState(() {});
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _createNewNote() {
    Navigator.of(context).pushNamed('/create_note');
    return;
  }

  void _openNote(Note note) async {
    await NoteViewHelper.viewNote(
      context,
      noteId: note.id,
      title: note.title,
      content: note.content,
      createdDate: note.date,
      updatedDate: note.date,
      attachmentUrl: note.attachmentName,
      attachmentType: note.attachmentType,
    );
  }

  void _openAttachment(Note note) async {
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
   
  }

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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'NotesCloud',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.of(context).pushNamed("/sign_in");
                // Handle logout
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logged out')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                onTap: null,
                value: 'profile',
                child: Text('Hi, Venkatesha'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi, Venkatesha',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  Icon(Icons.more_vert, color: Color(0xFF6B7280), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        child: Column(
          children: [
            // Header section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Notes',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_filteredNotes.length} notes total',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _createNewNote,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2937),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search your notes...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9CA3AF),
                        size: 20,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Notes list
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.all(24),
                      child: _filteredNotes.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No notes found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = _filteredNotes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: NoteCard(
                                    note: note,
                                    onTap: () => _openNote(note),
                                    onAttachmentTap: () =>
                                        _openAttachment(note),
                                    formatDate: _formatDate,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onAttachmentTap;
  final String Function(DateTime) formatDate;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onAttachmentTap,
    required this.formatDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
            // Title and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(note.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content preview
            Text(
              note.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Attachment
            GestureDetector(
              onTap: onAttachmentTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: Color(0xFF4A90E2),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        note.attachmentName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A90E2),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        note.attachmentType,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF4A90E2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
