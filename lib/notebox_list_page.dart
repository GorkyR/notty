import 'package:package_info/package_info.dart';

import 'formatter.dart';
import 'notebox_page.dart';
import 'notebox_creation_dialog.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'converters.dart';

class NoteDrawerPage extends StatefulWidget {
  NoteDrawerPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _NoteDrawerPageState createState() => _NoteDrawerPageState();
}

class _NoteDrawerPageState extends State<NoteDrawerPage> {
  bool boxes_are_fetched = false;
  List<NoteBox> boxes;

  void init() async {
    await init_database();
    boxes = await noteboxes();
    setState(() {
      boxes_are_fetched = true;
    });
  }

  _NoteDrawerPageState() {
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: "About...",
            onPressed: () async {
              final packageInfo = await PackageInfo.fromPlatform();
              showAboutDialog(
                  context: context,
                  applicationName: packageInfo.appName,
                  applicationVersion: packageInfo.version,
                  children: <Widget>[
                    Text("by Gorky Rojas."),
                    SizedBox(height: 12),
                    Text("A chat-like note-taking app."),
                  ]);
            },
          ),
        ],
      ),
      body: boxes_are_fetched
          ? ListView.separated(
              itemCount: boxes.length,
              itemBuilder: (context, i) => make_notebox(boxes[i]),
              separatorBuilder: (context, i) => Padding(
                  padding: EdgeInsets.fromLTRB(64, 4, 16, 4),
                  child: SizedBox(
                      height: 1,
                      child: Container(color: Colors.grey[200]))),
            )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create NoteBox',
        child: Icon(Icons.add_comment),
        foregroundColor: Colors.white,
        onPressed: () async {
          await showDialog(context: context, child: NoteBoxCreator());
          setState(() { boxes_are_fetched = false; });
          boxes = await noteboxes();
          setState(() { boxes_are_fetched = true; });
        },
      ),
    );
  }

  Widget make_notebox(NoteBox notebox) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Expanded(
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: ClipOval(
                    child: Container(
                        color: Color.lerp(
                            notecolor_to_color(notebox.color), null, 0.75),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            noteboxicon_to_icondata(notebox.icon),
                            color: notecolor_to_color(notebox.color),
                            size: 32,
                          ),
                        ))),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(notebox.title,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(notebox.notes.length.toString())
                      ],
                    ),
                    SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                      child: notebox.notes.isNotEmpty
                          ? RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(color: Colors.grey[500]),
                                children: format(notebox.notes.last.contents)
                                    .map((fts) => formattedtextspan_to_textspan(fts, active_hyperlinks: false)).toList()
                              )
                            )
                          : null,
                    ),
                  ],
                )
              )
            ],
          ),
        ),
      ),
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (context) => NoteBoxPage(notebox)));
        setState(() { boxes_are_fetched = false; });
        boxes = await noteboxes();
        setState(() { boxes_are_fetched = true; });
      },
    );
  }
}
