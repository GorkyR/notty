import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'notebox_list_page.dart';
import 'save_shared_page.dart';

void main() {
  runApp(NottyApp());
}

class NottyApp extends StatefulWidget {
  @override
  _NottyAppState createState() => _NottyAppState();
}

class _NottyAppState extends State<NottyApp> {
  StreamSubscription _shared_data_subscription;
  String _shared_data;

  @override
  void initState() {
    super.initState();

    _shared_data_subscription = ReceiveSharingIntent.getTextStream().listen((data) {
      setState(() {
        _shared_data = data;
      });
    });

    ReceiveSharingIntent.getInitialText().then((String data) {
      setState(() {
        _shared_data = data;
      });
    });


  }

  @override
  void dispose() {
    _shared_data_subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notty',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _shared_data == null
          ? NoteDrawerPage(title: 'Notes')
          : SaveSharedPage(data: _shared_data, callback: () {
            setState(() { _shared_data = null; });
          }),
    );
  }
}