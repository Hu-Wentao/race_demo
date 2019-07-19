import 'package:flutter/material.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
  final String title;
  const SettingsPage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsPageBloc _bloc = BlocProvider.of<SettingsPageBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextDivider(
              "Show speed in: ",
              padLTRB: [16, 8, 16, 0],
              showDivider: false,
            ),
            _buildSetSpeedUnit(context),
            TextDivider(
              "Show altitude in: ",
              padLTRB: [16, 8, 16, 0],
              showDivider: false,
            ),
            _buildSetAltitudeUnit(context),
            TextDivider(
              "Display position as: ",
              padLTRB: [16, 8, 16, 0],
              showDivider: false,
            ),
            _buildSetPositionStyle(context),
          ],
        ),
      ),
    );
  }

  _buildSetSpeedUnit(BuildContext context) {
    return RadiusContainer(
      child: ListTile(title: Text("test")),
    );
  }

  _buildSetAltitudeUnit(BuildContext context) {
    return RadiusContainer(
      child: ListTile(title: Text("test")),
    );
  }

  _buildSetPositionStyle(BuildContext context) {
    return RadiusContainer(
      child: ListTile(title: Text("test")),
    );
  }
}
