import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/note.dart';

class NoteForm extends StatefulWidget {
  final Note? note;

  const NoteForm({super.key, this.note});

  @override
  State<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<String> _categories = [
    'Umum',
    'Kuliah',
    'Pekerjaan',
    'Pribadi',
    'Penting',
  ];

  String _category = 'Umum';
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _category =
          _categories.contains(widget.note!.category)
              ? widget.note!.category
              : 'Umum';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);

    try {
      final note = Note(
        id: widget.note?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _category,
        createdAt: widget.note?.createdAt,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.update(note);
      } else {
        await DatabaseHelper.instance.insert(note);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan catatan: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Catatan' : 'Catatan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Judul catatan',
                  hintText: 'Masukkan judul',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  hintText: 'Tuliskan catatanmu di sini...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Isi catatan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _saveNote,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Catatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
