import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data.dart';
import 'formatter.dart';
import 'converters.dart';

class NoteBoxPage extends StatefulWidget {
  NoteBoxPage(this.notebox);

  final NoteBox notebox;

  @override
  _NoteBoxPageState createState() => _NoteBoxPageState();
}

class _NoteBoxPageState extends State<NoteBoxPage> {
  bool submit_button_enabled = false;
  TextEditingController note_editing_controller = TextEditingController();
  List<Note> selection = [];
  Note note_being_tapped;
  bool typing = false;
  Note note_being_edited;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leading_action_from_state(),
        title: selection.isEmpty
            ? Row(
                children: <Widget>[
                  Icon(noteboxicon_to_icondata(widget.notebox.icon)),
                  SizedBox(width: 6,),
                  Text(widget.notebox.title)
                ],
              )
            : null,
        actions: actions_from_selection(),
        backgroundColor: notecolor_to_color(widget.notebox.color),
      ),
      body: Container(
        color: Color.lerp(notecolor_to_color(widget.notebox.color),
            Color.fromRGBO(255, 255, 255, 0), 0.6875),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: widget.notebox.notes.length,
                itemBuilder: (context, i) =>
                    make_notebubble(widget.notebox.notes[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
//              IconButton(icon: Icon(Icons.add_box), iconSize: 28,),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                        child: TextField(
                          minLines: 1,
                          maxLines: 15,
                          decoration: InputDecoration(
                              hintText: "Type a note",
                              border: InputBorder.none),
                          controller: note_editing_controller,
                          onChanged: (string) {
                            setState(() { submit_button_enabled = string.isNotEmpty; });
                          },
                          cursorColor: notecolor_to_color(widget.notebox.color),
                          onTap: () { setState(() { typing = true; }); },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                    child: ClipOval(
                      child: Container(
                        color: Color.lerp(
                            notecolor_to_color(widget.notebox.color),
                            null,
                            submit_button_enabled ? 0.5 : 0.865),
                        child: IconButton(
                          onPressed: submit_button_enabled
                              ? (note_being_edited == null
                                ? () async {
                                    final note = Note(note_editing_controller.text);
                                    await add_note(widget.notebox, note);
                                    setState(() {
                                      note_editing_controller.clear();
                                      submit_button_enabled = false;
                                    });
                                  }
                                : () async {
                                    note_being_edited.contents = note_editing_controller.text;
                                    await update_note(note_being_edited);
                                    setState(() {
                                      note_editing_controller.clear();
                                      note_being_edited = null;
                                      note_being_tapped = null;
                                    });
                                  })
                              : null,
                          icon: note_being_edited == null? Icon(Icons.arrow_forward) : Icon(Icons.update),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget make_notebubble(Note note) {
    final in_selection = selection.contains(note);
    return GestureDetector(
      onTapDown: (details) {
        setState(() { note_being_tapped = note; });
      },
      onTapUp: (details) {
        setState(() { note_being_tapped = null; });
      },
      onLongPress: () {
        if (selection.isEmpty) {
          setState(() { selection.add(note); });
        }
      },
      onTap: () {
        if (selection.isNotEmpty) {
          setState(() {
            if (in_selection)
              selection.remove(note);
            else
              selection.add(note);
          });
        }
      },
      child: Container(
        color: in_selection
          ? Color.lerp(Colors.lightBlueAccent, null, 0.5)
          : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: formattedtexts_to_widgets(format(note.contents)),
//              child: RichText(
//                text: TextSpan(
//                  style: Theme.of(context).textTheme.bodyText2,
//                  children: format(note.contents)
//                      .map(formattedtextspan_to_textspan)
//                      .toList(),
//                ),
//              ),
            ),
            color: note_being_tapped == note || in_selection
                ? Color.lerp(Colors.lightBlueAccent, null, 0.5)
                : Color.lerp(notecolor_to_color(widget.notebox.color), Colors.white70, 0.5),
          ),
        ),
      ),
    );
  }

  void delete_selected() async {
    // TODO: pop a dialog asking if you *really* want to delete the notes
    for (var note in selection) {
      await delete_note(widget.notebox, note);
    }
  }

  List<Widget> actions_from_selection() {
    if (selection.isNotEmpty) {
      final delete_button = IconButton(
        icon: Icon(Icons.delete),
        tooltip: "Delete",
        onPressed: () async {
          final number_of_selected_notes = selection.length;
          await delete_selected();
          Fluttertoast.showToast(context, msg: "$number_of_selected_notes note${number_of_selected_notes == 1? "" : "s"} deleted", gravity: ToastGravity.CENTER);
          setState(() { selection.clear(); });
        },
      );

      final copy_button = IconButton(
        icon: Icon(Icons.content_copy),
        tooltip: "Copy text",
        onPressed: () {
          selection.sort((a, b) => a.id.compareTo(b.id));
          final merged_text = selection.map((n) => n.contents).join("\n\n");
          Clipboard.setData(ClipboardData(text: merged_text));
          Fluttertoast.showToast(context, msg: "Text copied", gravity: ToastGravity.CENTER);
          setState(() { selection.clear(); });
        },
      );

      if (selection.length == 1) {
        return [
          delete_button,
          copy_button,
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: "Edit note",
            onPressed: () {
              final note_to_edit = selection.first;
              note_editing_controller.text = note_to_edit.contents;
              setState(() {
                note_being_edited = note_to_edit;
                selection.clear();
              });
            },
          ),
        ];
      } else {
        return [
          delete_button,
          copy_button,
          IconButton(
            icon: Icon(Icons.merge_type),
            tooltip: "Merge notes",
            onPressed: () async {
              selection.sort((a, b) => a.id.compareTo(b.id));
              final merged_text = selection.map((n) => n.contents).join("\n\n");
              await add_note(widget.notebox, Note(merged_text));
              for (var note in selection) {
                await delete_note(widget.notebox, note);
              }
              setState(() { selection.clear(); });
            },
          ),
        ];
      }
    }
    else if (typing) {
      return [
        IconButton(
          icon: Stack(children: [
            Center(child: Icon(Icons.check_box_outline_blank)),
            Center(child: Icon(Icons.add, size: 18,))
          ]),
          tooltip: "Add checkbox",
          onPressed: () {
            final selection = note_editing_controller.selection;
            final text_before_selection = note_editing_controller.text.substring(0, selection.start);
            final text_inside_selection = note_editing_controller.text.substring(selection.start, selection.end);
            final text_after_selection = note_editing_controller.text.substring(selection.end);
            const checkbox_text = "\n[[]] ";
            final text_with_checkbox_added = text_before_selection + checkbox_text + text_inside_selection + text_after_selection;
            note_editing_controller.text = text_with_checkbox_added;
            final new_cursor_position = selection.end + checkbox_text.length;
            note_editing_controller.selection = selection.copyWith(baseOffset: new_cursor_position, extentOffset: new_cursor_position);
          }
        ),
      ];
    }
  }
  Widget leading_action_from_state() {
    if (selection.isNotEmpty)
      return IconButton(
        icon: Icon(Icons.clear),
        tooltip: "Clear selection",
        onPressed: () {
          setState(() { selection.clear(); });
        },
      );
    else if (note_being_edited != null)
      return IconButton(
        icon: Icon(Icons.cancel),
        tooltip: "Cancel editing",
        onPressed: () {
          setState(() {
            note_editing_controller.clear();
            note_being_edited = null;
            note_being_tapped = null;
          });
        },
      );
  }
}
