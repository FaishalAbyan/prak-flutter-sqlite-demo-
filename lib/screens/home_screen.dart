import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/note.dart';
import 'note_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _loading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);

    try {
      final notes =
          _keyword.isEmpty
              ? await DatabaseHelper.instance.getAllNotes()
              : await DatabaseHelper.instance.searchNotes(_keyword);

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat catatan: $e')));
    }
  }

  Future<void> _openForm({Note? note}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteForm(note: note)),
    );

    if (result == true) {
      await _loadNotes();
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Catatan?'),
          content: Text(
            'Catatan "${note.title}" akan dihapus secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || note.id == null) return;

    try {
      await DatabaseHelper.instance.delete(note.id!);
      await _loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catatan berhasil dihapus')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus catatan: $e')));
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatanku'), centerTitle: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari judul atau isi catatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _keyword.isNotEmpty
                        ? IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _keyword = '');
                            _loadNotes();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (value) {
                _keyword = value.trim();
                _loadNotes();
              },
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _notes.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _keyword.isEmpty
                                  ? 'Belum ada catatan'
                                  : 'Catatan tidak ditemukan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _keyword.isEmpty
                                  ? 'Tekan tombol + untuk membuat catatan.'
                                  : 'Coba gunakan kata kunci lain.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Pilihan catatan',
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _openForm(note: note);
                                        } else if (value == 'delete') {
                                          _confirmDelete(note);
                                        }
                                      },
                                      itemBuilder:
                                          (context) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Hapus'),
                                                ],
                                              ),
                                            ),
                                          ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Chip(
                                      avatar: const Icon(
                                        Icons.category_outlined,
                                        size: 16,
                                      ),
                                      label: Text(note.category),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatDate(note.createdAt),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
      ),
    );
  }
}
