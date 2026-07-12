import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class IbChapterContentsBuilder extends MarkdownElementBuilder {
  IbChapterContentsBuilder({this.chapterContents});

  final Widget? chapterContents;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) =>
      const SizedBox.shrink();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return chapterContents;
  }
}
