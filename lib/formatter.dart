// *bold*
// _italics_
// __underlined__
// ^> quote

// `monospace`
// ~strikethrough~
// ^# title

import 'package:flutter/material.dart';

enum SpanStyle { bold, italics, strikethrough, monospace, underline, hyperlink, title, quote }

final modifier_to_style = {
  "*": SpanStyle.bold,
  "__": SpanStyle.underline,
  "~": SpanStyle.strikethrough,
  "`": SpanStyle.monospace,
  "_": SpanStyle.italics,
};

final modifiers = modifier_to_style.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

final style_to_modifier = {
  SpanStyle.bold: "*",
  SpanStyle.underline: "__",
  SpanStyle.italics: "_",
  SpanStyle.strikethrough: "~",
  SpanStyle.monospace: "`",
  SpanStyle.hyperlink: "",
};

String starts_with_which(String input, Iterable<String> patterns) {
  for (var pattern in patterns)
    if (input.startsWith(pattern))
      return pattern;
  return null;
}

class FormattedText {
  String text;
  List<SpanStyle> styles = [];

  FormattedText({this.text = "", List<SpanStyle> styles}){
    if (styles != null)
      this.styles = styles;
  }
  FormattedText.new_line() {
    this.text = "\n";
  }
  FormattedText.title(this.text) {
    this.styles.add(SpanStyle.title);
  }
}

enum FormatTokenType { none, modifier, escaped_sequence, hyperlink }

class FormatToken {
  String text;
  int offset;
  FormatTokenType type;
  int skip;

  FormatToken({this.text, this.offset, this.type});
  FormatToken.all(String input) {
    this.offset = this.skip = input.length;
    this.type = FormatTokenType.none;
  }
}

FormatToken next_token(String input) {
  FormatToken token = FormatToken.all(input);

  var offset = input.indexOf("\\");
  if (offset >= 0) {
    token = FormatToken(
      offset: offset,
      type: FormatTokenType.escaped_sequence,
      text: offset + 1 < input.length && modifiers.contains(input[offset + 1])
          ? input[offset + 1]
          : '\\',
    );
    token.skip = token.offset + (token.text == '\\'? 1 : token.text.length + 1);
  }
  for (var modifier in modifiers) {
    final offset = input.indexOf(modifier);
    if (offset >= 0 && offset < token.offset) {
      token = FormatToken(
        offset: offset,
        type: FormatTokenType.modifier,
        text: modifier,
      );
      token.skip = token.offset + modifier.length;
    }
  }
  final url_match = re_url.firstMatch(input);
  if (url_match != null && url_match.start < token.offset) {
    token = FormatToken(
      offset: url_match.start,
      type: FormatTokenType.hyperlink,
      text: url_match.group(0),
    );
    token.skip = token.offset + url_match.group(0).length;
  }

  return token;
}

List<FormattedText> format(String note_text) {
  List<FormattedText> spans = [FormattedText()];
  for (var line in note_text.split("\n")) {
    if (line.startsWith("# ")) {
      if (spans.last.text.isEmpty)
        spans.removeLast();
      spans.add(FormattedText.title(line.substring(2)));
      spans.add(FormattedText(text: ""));
    }
    else {
      int offset = 0;
      if (line.startsWith("> ")) {
        spans.last.styles.add(SpanStyle.quote);
        offset = 2;
      }
      while (offset < line.length) {
        final token = next_token(line.substring(offset));
        spans.last.text += line.substring(offset, offset + token.offset);
        switch (token.type) {
          case FormatTokenType.modifier: {
            final style = modifier_to_style[token.text];
            if (spans.last.styles.isNotEmpty &&
                spans.last.styles.last == style) {
              spans.add(FormattedText(
                  styles: spans.last.styles.sublist(
                      0, spans.last.styles.length - 1)));
            }
            else if (spans.last.styles.contains(style)) {
              spans = cancel_style(spans, style);
            }
            else {
              final new_span = FormattedText(
                  styles: List.from(spans.last.styles));
              new_span.styles.add(style);
              spans.add(new_span);
            }
          } break;
          case FormatTokenType.hyperlink: {
            final List<SpanStyle> prev_styles = List.from(spans.last.styles);
            final hyperlink_span = FormattedText(
                text: token.text,
                styles: List.from(spans.last.styles)
            );
            hyperlink_span.styles.add(SpanStyle.hyperlink);
            spans.add(hyperlink_span);
            spans.add(FormattedText(styles: prev_styles));
          } break;
          case FormatTokenType.escaped_sequence: {
            spans.last.text += token.text;
          } break;
          default: {
            if (spans.last.styles.isNotEmpty) {
              spans = cancel_style(spans, spans.last.styles.first);
            }
          }
        }
        offset += token.skip;
      }
      spans.add(FormattedText.new_line());
    }
  }
  return spans
      ..removeLast();
}

List<FormattedText> cancel_style(List<FormattedText> list, SpanStyle style) {
  // TODO: preserve hyperlinks here
  if (list.last.styles.length != 1 || style != SpanStyle.quote) {
    final cancel_from = list.last.styles.indexOf(style);
    list[cancel_from].text = list
        .sublist(cancel_from)
        .map((ft) => style_to_modifier[ft.styles.last] + ft.text)
        .join();
    return list.sublist(0, cancel_from + 1);
  }
  return list;
}

List<FormattedText> _format(String note_text) {
  List<FormattedText> spans = [FormattedText()];
  for (var line in note_text.split("\n")) {
    int index = 0;
    while (index < line.length) {
      String pattern;
      if (line[index] == '\\') {
        if (index + 1 < line.length && modifier_to_style.keys.contains(line[index + 1])) {
          spans.last.text += line[index + 1];
          index += 1;
        }
        else
          spans.last.text += line[index];
      }
      else if ((pattern = starts_with_which(line.substring(index), modifiers)) != null) {
        final style = modifier_to_style[pattern];
        if (spans.last.styles.isNotEmpty && spans.last.styles.last == style) {
          spans.add(FormattedText(
              styles: spans.last.styles.sublist(0, spans.last.styles.length - 1)));
        }
        else if (spans.last.styles.contains(style)) {
          final join_from = spans.last.styles.indexOf(style);
          spans[join_from].text = spans.sublist(join_from).map((ft) => style_to_modifier[ft.styles.last] + ft.text).join();
          spans = spans.sublist(0, join_from + 1);
        }
        else {
          final new_span = FormattedText(styles: List.from(spans.last.styles));
          new_span.styles.add(style);
          spans.add(new_span);
        }
        index += pattern.length - 1;
      }
      else {
        spans.last.text += line[index];
      }
      index += 1;
    }
    spans.add(FormattedText(text: "\n"));
  }
  return spans
    ..removeLast();
}

final re_url_protocol = new RegExp("(?:(?:(?:https?|ftp):)?\\/\\/)");
final re_url = new RegExp(
  // protocol identifier (optional)
  // short syntax // still required
  "(?:(?:(?:https?|ftp):)?\\/\\/)?" +
  // user:pass BasicAuth (optional)
  "(?:\\S+(?::\\S*)?@)?" +
  "(?:" +
  // IP address exclusion
  // private & local networks
  "(?!(?:10|127)(?:\\.\\d{1,3}){3})" +
  "(?!(?:169\\.254|192\\.168)(?:\\.\\d{1,3}){2})" +
  "(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})" +
  // IP address dotted notation octets
  // excludes loopback network 0.0.0.0
  // excludes reserved space >= 224.0.0.0
  // excludes network & broadcast addresses
  // (first & last IP address of each class)
  "(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])" +
  "(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}" +
  "(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))" +
  "|" +
  // host & domain names, may end with dot
  // can be replaced by a shortest alternative
  // (?![-_])(?:[-\\w\\u00a1-\\uffff]{0,63}[^-_]\\.)+
  "(?:" +
  "(?:" +
  "[a-z0-9\\u00a1-\\uffff]" +
  "[a-z0-9\\u00a1-\\uffff_-]{0,62}" +
  ")?" +
  "[a-z0-9\\u00a1-\\uffff]\\." +
  ")+" +
  // TLD identifier name, may end with dot
  "(?:[a-z\\u00a1-\\uffff]{2,}\\.?)" +
  ")" +
  // port number (optional)
  "(?::\\d{2,5})?" +
  // resource path (optional)
  "(?:[/?#]\\S*)?",
  caseSensitive: false,
  unicode: true,
);