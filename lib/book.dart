class Book {
  const Book(
      {this.id,
      required this.title,
      required this.author,
      required this.pages,
      required this.genre,
      this.isRead = false,
      required this.addedDate});
  final int? id;
  final String title, author, genre;
  final int pages;
  final bool isRead;
  final DateTime addedDate;
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'author': author,
        'pages': pages,
        'genre': genre,
        'isRead': isRead ? 1 : 0,
        'addedDate': addedDate.toUtc().toIso8601String()
      };
  factory Book.fromMap(Map<String, Object?> m) => Book(
      id: m['id'] as int,
      title: m['title'] as String,
      author: m['author'] as String,
      pages: m['pages'] as int,
      genre: m['genre'] as String,
      isRead: m['isRead'] == 1,
      addedDate: DateTime.parse(m['addedDate'] as String));
}
