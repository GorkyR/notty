import 'package:Notty/converters.dart';
import 'package:Notty/notebox_page.dart';
import 'package:flutter/material.dart';

import 'data.dart';

class SaveSharedPage extends StatefulWidget {
  SaveSharedPage({this.data, this.callback});
  final String data;
  final Function() callback;

  @override
  _SaveSharedPageState createState() => _SaveSharedPageState();
}

class _SaveSharedPageState extends State<SaveSharedPage> {
  List<NoteBox> boxes;
  bool boxes_are_fetched = false;

  void init() async {
    await init_database();
    boxes = await noteboxes();
    setState(() { boxes_are_fetched = true; });
  }

  _SaveSharedPageState() {
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Save to..."),),
      body: boxes_are_fetched
        ? ListView.separated(
            itemCount: boxes.length,
            itemBuilder: (context, index) =>
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      ClipOval(
                        child: Container(
                          color: Color.lerp(
                              notecolor_to_color(boxes[index].color), null, 0.75),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            noteboxicon_to_icondata(boxes[index].icon),
                            color: notecolor_to_color(boxes[index].color),)
                        ),
                      ),
                      SizedBox(width: 8,),
                      Text(boxes[index].title,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) =>
                          NoteBoxPage(boxes[index], text: widget.data)));
                  widget.callback();
                },
              )
            , separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(58, 4, 16, 4),
                child: SizedBox(
                    height: 1,
                    child: Container(color: Colors.grey[200])
                )
              )
          )
        : Container(),
    );
  }
}