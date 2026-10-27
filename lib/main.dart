import 'package:flutter/material.dart';
import 'book.dart';
import 'database_helper.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, home: LibraryScreen()));

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repo = BookRepository();
  List<Book> _books = [];
  Map<String, int> _stats = {'total': 0, 'read': 0};
  String _search = '';
  bool? _read;
  bool _desc = true;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _error(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Помилка: $e')));
    }
  }

  Future<void> _reload() async {
    final request = ++_request;
    try {
      final books = await _repo.getAll(
          author: _search, isRead: _read, newestFirst: _desc);
      final stats = await _repo.getStatistics();
      if (mounted && request == _request) {
        setState(() {
          _books = books;
          _stats = stats;
        });
      }
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _act(Future<Object?> Function() action) async {
    try {
      await action();
      await _reload();
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _add() async {
    final book = await Navigator.of(context)
        .push<Book>(MaterialPageRoute(builder: (_) => const BookForm()));
    if (book != null) await _act(() => _repo.insert(book));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Книжкова бібліотека'), actions: [
        IconButton(
            onPressed: () {
              _desc = !_desc;
              _reload();
            },
            icon: const Icon(Icons.sort))
      ]),
      floatingActionButton:
          FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
                decoration:
                    const InputDecoration(labelText: 'Пошук за автором'),
                onChanged: (v) {
                  _search = v;
                  _reload();
                })),
        Wrap(spacing: 8, children: [
          for (final value in <bool?>[null, false, true])
            ChoiceChip(
                label: Text(value == null
                    ? 'Усі'
                    : value
                        ? 'Прочитані'
                        : 'Непрочитані'),
                selected: _read == value,
                onSelected: (_) {
                  _read = value;
                  _reload();
                })
        ]),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
                'Всього: ${_stats['total']} · Прочитано: ${_stats['read']}')),
        Expanded(
            child: _books.isEmpty
                ? const Center(child: Text('Книг не знайдено'))
                : ListView.builder(
                    itemCount: _books.length,
                    itemBuilder: (context, i) {
                      final b = _books[i];
                      return ListTile(
                          title: Text(b.title),
                          subtitle:
                              Text('${b.author} · ${b.pages} с. · ${b.genre}'),
                          leading: Checkbox(
                              value: b.isRead,
                              onChanged: (v) => _act(
                                  () => _repo.updateReadStatus(b.id!, v!))),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _act(() => _repo.delete(b.id!))));
                    })),
      ]));
}

class BookForm extends StatefulWidget {
  const BookForm({super.key});
  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _author = TextEditingController(),
      _pages = TextEditingController(),
      _genre = TextEditingController();
  @override
  void dispose() {
    for (final c in [_title, _author, _pages, _genre]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Нова книга')),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final pair in [
              (_title, 'Назва'),
              (_author, 'Автор'),
              (_genre, 'Жанр')
            ])
              TextFormField(
                  controller: pair.$1,
                  decoration: InputDecoration(labelText: pair.$2),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Заповніть поле' : null),
            TextFormField(
                controller: _pages,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Сторінок'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Введіть додатне ціле число'
                    : null),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    Navigator.pop(
                        context,
                        Book(
                            title: _title.text.trim(),
                            author: _author.text.trim(),
                            pages: int.parse(_pages.text),
                            genre: _genre.text.trim(),
                            addedDate: DateTime.now()));
                  }
                },
                child: const Text('Додати книгу')),
          ])));
}
