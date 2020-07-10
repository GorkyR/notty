import 'package:Notty/data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'converters.dart';

class NoteBoxCreator extends StatefulWidget {
  @override
  _NoteBoxCreatorState createState() => _NoteBoxCreatorState();
}

class _NoteBoxCreatorState extends State<NoteBoxCreator> {
  final double button_size = 48;
  final double label_size = 14;
  final double gutter = 16;

  TextEditingController title = TextEditingController();
  NoteColor color = NoteColor.values[0];
  NoteBoxIcon icon = NoteBoxIcon.values[0];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                maxLines: 1,
                controller: title,
                decoration: InputDecoration(labelText: "Title"),
                style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: gutter),
              Text("Color:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: label_size)),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: (button_size + 16) * 3),
                  child: Wrap(
                    direction: Axis.horizontal,
                    children: List.generate(NoteColor.values.length, (index) => color_button(index))
                  ),
                ),
              ),
              SizedBox(height: gutter),
              Text("Icon:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: label_size)),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: (button_size + 16) * 3),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    direction: Axis.horizontal,
                    children: List.generate(NoteBoxIcon.values.length, (index) => icon_button(index))
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FlatButton(
                      child: Text("CANCEL"),
                      onPressed: () { Navigator.of(context).pop(); },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      child: Text("CREATE"),
                      onPressed: () async {
                        final notebox = NoteBox(title.text, color: color, icon: icon);
                        await add_notebox(notebox);
                        Navigator.of(context).pop();
                      },
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget color_button(int index) {
    return ClipOval(
      child: Container(
        color: color != null && color.index == index
            ? Color.lerp(notecolor_to_color(color), null, 0.5)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(500),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipOval(
              child: SizedBox(
                width: button_size,
                height: button_size,
                child: Container(color: notecolor_to_color(NoteColor.values[index]),),
              )
            ),
          ),
          onTap: () { setState(() { color = NoteColor.values[index]; }); },
        ),
      ),
    );
  }

  Widget icon_button(int index) {
    return ClipOval(
      child: Container(
        color: icon != null && icon.index == index
            ? Color.lerp(notecolor_to_color(color), null, 0.75)
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(500),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipOval(
                child: SizedBox(
                  width: button_size,
                  height: button_size,
                  child: Container(
                    color: Color.lerp(notecolor_to_color(color), null, 0.75),
                    child: Icon(noteboxicon_to_icondata(NoteBoxIcon.values[index]),
                      color: notecolor_to_color(color),
                      size: 32),
                  ),
                )
            ),
          ),
          onTap: () { setState(() { icon = NoteBoxIcon.values[index]; }); },
        ),
      ),
    );
  }
}