import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/note.dart';

class DatabaseHelper {
  DatabaseHelper._init();

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _factoryInitialized = false;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _initializeDatabaseFactory();

    _database = await _initDB('notes.db');
    return _database!;
  }

  void _initializeDatabaseFactory() {
    if (_factoryInitialized) return;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryInitialized = true;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Umum',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE notes ADD COLUMN category TEXT NOT NULL DEFAULT 'Umum'",
      );

      await db.execute(
        "ALTER TABLE notes ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
      );

      await db.execute(
        "UPDATE notes SET created_at = datetime('now') WHERE created_at = ''",
      );
    }
  }

  Future<int> insert(Note note) async {
    final db = await database;
    final data = note.toMap()..remove('id');

    return db.insert('notes', data);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;

    final result = await db.query('notes', orderBy: 'id DESC');

    return result.map((row) => Note.fromMap(row)).toList();
  }

  Future<List<Note>> searchNotes(String keyword) async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );

    return result.map((row) => Note.fromMap(row)).toList();
  }

  Future<int> update(Note note) async {
    final db = await database;
    final data = note.toMap()..remove('id');

    return db.update('notes', data, where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> delete(int id) async {
    final db = await database;

    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
