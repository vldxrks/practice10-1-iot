import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'book.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();
  Future<Database>? _opening;
  Future<Database> get database => _opening ??= initDB();
  Future<Database> initDB() async {
    try {
      return await openDatabase(join(await getDatabasesPath(), 'books.db'),
          version: 1, onCreate: createDB);
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> createDB(Database db, int version) async {
    await db.execute(
        'CREATE TABLE books(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,author TEXT NOT NULL,pages INTEGER NOT NULL CHECK(pages>0),genre TEXT NOT NULL,isRead INTEGER NOT NULL CHECK(isRead IN (0,1)),addedDate TEXT NOT NULL)');
    await db.execute('CREATE INDEX idx_books_author ON books(author)');
  }
}

class BookRepository {
  Future<int> insert(Book b) async =>
      (await DatabaseHelper.instance.database).insert('books', b.toMap());
  Future<List<Book>> getAll(
      {String author = '', bool? isRead, bool newestFirst = true}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('books',
        where: 'author LIKE ?${isRead == null ? '' : ' AND isRead = ?'}',
        whereArgs: ['%$author%', if (isRead != null) isRead ? 1 : 0],
        orderBy:
            'addedDate ${newestFirst ? 'DESC' : 'ASC'}, id ${newestFirst ? 'DESC' : 'ASC'}');
    return rows.map(Book.fromMap).toList();
  }

  Future<List<Book>> searchByAuthor(String author) => getAll(author: author);
  Future<int> updateReadStatus(int id, bool isRead) async =>
      (await DatabaseHelper.instance.database).update(
          'books', {'isRead': isRead ? 1 : 0},
          where: 'id = ?', whereArgs: [id]);
  Future<int> delete(int id) async => (await DatabaseHelper.instance.database)
      .delete('books', where: 'id = ?', whereArgs: [id]);
  Future<Map<String, int>> getStatistics() async {
    final rows = await (await DatabaseHelper.instance.database).rawQuery(
        'SELECT COUNT(*) AS total, COALESCE(SUM(isRead),0) AS read FROM books');
    return {
      'total': rows.first['total'] as int,
      'read': rows.first['read'] as int
    };
  }
}
