import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final database_name   = "notes_database.db";
final table_noteboxes = "noteboxes";
final table_notes     = "notes";
Database database;

void init_database() async {
  database = await openDatabase(
    join(await getDatabasesPath(), database_name),
    onCreate: (db, version) {
      db.execute("create table $table_noteboxes(id integer primary key autoincrement, title text, color integer, icon integer)");
      db.execute("create table $table_notes(id integer primary key autoincrement, notebox integer, contents text, created integer" +
          ", foreign key (notebox) references $table_noteboxes(id))");
      db.insert(table_noteboxes, { "title": "Box", "color": 0, "icon": 0 });
    },
    version: 1
  );
}

Future<List<NoteBox>> noteboxes() async {
  final noteboxes_info = await database.query(table_noteboxes);
  final noteboxes = List.generate(
      noteboxes_info.length,
      (i) => NoteBox(
        noteboxes_info[i]['title'],
        color: NoteColor.values[noteboxes_info[i]['color']],
        icon: NoteBoxIcon.values[noteboxes_info[i]['icon']],)
        ..id = noteboxes_info[i]['id']);

  for (var notebox in noteboxes) {
    final notes_info = await database.query(
      table_notes,
      where: "notebox = ?",
      whereArgs: [notebox.id]
    );
    notebox.notes = List.generate(notes_info.length,
      (i) => Note(
        notes_info[i]['contents'],
        id: notes_info[i]['id'],
        created: notes_info[i]['created']));
  }

  return noteboxes;
}

void add_notebox(NoteBox notebox) async {
  notebox.id = await database.insert(
      table_noteboxes,
      notebox.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
}

void add_note(NoteBox box, Note note) async {
  note.id = await database.insert(
      table_notes,
      { 'contents': note.contents, 'created': note.created.millisecondsSinceEpoch, 'notebox': box.id },
      conflictAlgorithm: ConflictAlgorithm.replace
  );
  box.notes.add(note);
}

void delete_note(NoteBox box, Note note) async {
  await database.delete(
    table_notes,
    where: "id = ?",
    whereArgs: [note.id]
  );
  box.notes.remove(note);
}

void update_note(Note note) async {
  await database.update(
    table_notes,
    { "contents": note.contents },
    where: "id = ?",
    whereArgs: [note.id],
  );
}

enum NoteColor { grey, black, blue, pink, yellow, red, green, purple, teal }
enum NoteBoxIcon { note, bubbles, links, to_do, time, attatchment, photos, idea, love, }

class Note {
  int id;
  String contents;
  DateTime created;

  Note(this.contents, {this.id, int created}) {
    if (created != null)
      this.created = DateTime.fromMicrosecondsSinceEpoch(created);
    else
      this.created = DateTime.now();
  }
}

class NoteBox {
  int id;
  String title;
  NoteColor color;
  NoteBoxIcon icon;
  List<Note> notes = [];

  NoteBox(this.title, {this.color, this.icon = NoteBoxIcon.note, this.id});

  Map<String, dynamic> toMap() => { 'title': title, 'color': color.index, 'icon': icon.index };
}