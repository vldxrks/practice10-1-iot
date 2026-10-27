import 'package:flutter_test/flutter_test.dart';
import 'package:practice10/book.dart';

void main() {
  test('Книга зберігає дані та статус прочитання', () {
    final book = Book(
      id: 1,
      title: 'Кобзар',
      author: 'Тарас Шевченко',
      pages: 300,
      genre: 'Поезія',
      isRead: true,
      addedDate: DateTime.utc(2026, 10, 27),
    );

    final map = book.toMap();
    expect(map['isRead'], 1);

    final restored = Book.fromMap(map);
    expect(restored.title, book.title);
    expect(restored.author, book.author);
    expect(restored.pages, 300);
    expect(restored.isRead, isTrue);
    expect(restored.addedDate, book.addedDate);
  });
}
