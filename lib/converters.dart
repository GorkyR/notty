

import 'package:Notty/formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

Color notecolor_to_color(NoteColor color) {
  switch(color) {
    case NoteColor.grey:
      return Colors.grey[600];
    case NoteColor.pink:
      return Colors.pink[300];
    case NoteColor.blue:
      return Colors.blue;
    case NoteColor.yellow:
      return Colors.yellow[600];
    case NoteColor.red:
      return Colors.red;
    case NoteColor.purple:
      return Colors.purple;
    case NoteColor.green:
      return Colors.green;
    case NoteColor.black:
      return Colors.black;
    case NoteColor.teal:
      return Colors.teal;
    default:
      return Colors.grey;
  }
}

IconData noteboxicon_to_icondata(NoteBoxIcon icon) {
  switch(icon) {
    case NoteBoxIcon.note:
      return Icons.event_note;
    case NoteBoxIcon.bubbles:
      return Icons.bubble_chart;
    case NoteBoxIcon.links:
      return Icons.link;
    case NoteBoxIcon.to_do:
      return Icons.done_all;
    case NoteBoxIcon.time:
      return Icons.alarm_on;
    case NoteBoxIcon.attatchment:
      return Icons.attach_file;
    case NoteBoxIcon.photos:
      return Icons.photo_camera;
    case NoteBoxIcon.idea:
      return Icons.lightbulb_outline;
    case NoteBoxIcon.love:
      return Icons.favorite;
    default:
      return Icons.edit;
  }
}

bool contains_any_of(Iterable<Object> iterable, Iterable<Object> items) {
  for (var item in items)
    if (iterable.contains(item))
      return true;
  return false;
}

TextSpan formattedtextspan_to_textspan(FormattedText span, {bool active_hyperlinks: true}) {
  bool is_hyperlink = span.styles.contains(SpanStyle.hyperlink);
  List<TextDecoration> decorations = [];
  if (span.styles.contains(SpanStyle.underline) || is_hyperlink)
    decorations.add(TextDecoration.underline);
  if (span.styles.contains(SpanStyle.strikethrough))
    decorations.add(TextDecoration.lineThrough);

  return TextSpan(
    text: span.text,
    style: TextStyle(
      fontWeight: contains_any_of(span.styles, [SpanStyle.bold, SpanStyle.title])? FontWeight.bold : FontWeight.normal,
      fontSize: span.styles.contains(SpanStyle.title)? 24 : null,
      fontStyle: span.styles.contains(SpanStyle.italics)? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.combine(decorations),
      fontFamily: span.styles.contains(SpanStyle.monospace)? "FiraCode" : null,
      color: is_hyperlink && active_hyperlinks? Colors.blue : null,
    ),
    recognizer: is_hyperlink && active_hyperlinks
      ? (TapGestureRecognizer()
          ..onTap = () { launch((span.text.startsWith(re_url_protocol)? "" : "http://") + span.text); })
      : null,
  );
}

Column formattedtexts_to_widgets(List<FormattedText> texts) {
  RichText default_text() => RichText(text: TextSpan(style: TextStyle(color: Colors.black), children: []));
  List<Widget> widgets = [default_text()];
  for (var text in texts) {
    if (text.styles.contains(SpanStyle.title)) {
      widgets.add(RichText(
          text: TextSpan(
            text: text.text,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
          )
      ));
      widgets.add(default_text());
    }
    else if (text.styles.contains(SpanStyle.quote)) {
      final last_widget = widgets.last;
      if (last_widget is Container) {
        ((last_widget.child as RichText).text as TextSpan).children
            .add(formattedtextspan_to_textspan(text));
      } else if (last_widget is RichText) {
        widgets.add(Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.0625),
            border: Border(left: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.5), width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          child: default_text()
        ));
        (((widgets.last as Container).child as RichText).text as TextSpan).children
            .add(formattedtextspan_to_textspan(text));
      }
    }
    else {
      final last_widget = widgets.last;
      if (last_widget is RichText) {
        (last_widget.text as TextSpan).children.add(formattedtextspan_to_textspan(text));
      } else if (last_widget is Container) {
        widgets.add(default_text());
        ((widgets.last as RichText).text as TextSpan).children.add(formattedtextspan_to_textspan(text
          ..text = text.text.substring(1)));
      }
    }
  }

  if (((widgets.first as RichText).text as TextSpan).children.isEmpty) {
    widgets.removeAt(0);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start,
    children: widgets,
  );
}