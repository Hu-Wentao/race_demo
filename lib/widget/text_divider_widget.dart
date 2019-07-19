import 'package:flutter/material.dart';

/// 帶一条线的标题
class TextDivider extends StatelessWidget {
  final String title;
  final Color textColor;
  final List<double> padLTRB;
  final bool showDivider;

  TextDivider(
    this.title, {
    Key key,
    this.padLTRB: const [16.0, 8.0, 16.0, 8.0],
    this.showDivider: true,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Text titleText = Text(
      this.title,
      textAlign: TextAlign.start,
      style: TextStyle(color: this.textColor??Theme.of(context).primaryColor),
    );
    return Padding(
      padding:
          EdgeInsets.fromLTRB(padLTRB[0], padLTRB[1], padLTRB[2], padLTRB[3]),
      child: showDivider
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[titleText, Divider()],
            )
          : Row(
              children: <Widget>[titleText],
            ),
    );
  }
}
