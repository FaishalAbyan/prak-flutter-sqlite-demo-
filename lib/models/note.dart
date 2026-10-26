class Note {
  final int? id;
  final String title;
  final String content;
  final String category;
  final String createdAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.category = 'Umum',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'created_at': createdAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      category: (map['category'] as String?) ?? 'Umum',
      createdAt:
          (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }
}
