
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/home_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/widget/none_border_color_expansion_tile.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
  final HomeBloc homeBloc;
//  final Key checkUpdateBtnKey = const ValueKey("checkUpdateBtnKey");

  const SettingsPage(this.homeBloc, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsPageBloc _settingsBloc =
        BlocProvider.of<SettingsPageBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 48),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextDivider(
                "Show speed in: ",
              ),
              RadiusContainer(
                child: _buildSetSpeedUnit(context),
              ),
              TextDivider(
                "Show altitude in: ",
              ),
              RadiusContainer(
                child: _buildSetAltitudeUnit(context),
              ),
              TextDivider(
                "Display position as: ",
              ),
              RadiusContainer(
                child: _buildSetPositionStyle(context),
              ),
              TextDivider(
                "About device",
              ),

              RadiusContainer(
                child: _buildUpgradeFirmware(context, homeBloc, _settingsBloc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildSetSpeedUnit(BuildContext context) {
    return ListTile();
  }

  _buildSetAltitudeUnit(BuildContext context) {
    return ListTile();
  }

  _buildSetPositionStyle(BuildContext context) {
    return ListTile();
  }

  _buildUpgradeFirmware(
      BuildContext context, HomeBloc homeBloc, SettingsPageBloc settingsBloc) {
    final greyTextStyle =
        TextStyle(color: Theme.of(context).textTheme.caption.color);

    return StreamBuilder<UpdateProgressInfo>(
      stream: settingsBloc.outUpdateProgress,
      initialData: UpdateProgressInfo(
        OadPhase.UN_OAD,
        "un oad",
        phraseProgress: 0.0,
      ),
      builder: (context, snap) {
        String updatePhaseMsg = snap.data.phaseMsg;

        return NoneBorderColorExpansionTile(
          title: Text("Upgrade Firmware"),
          trailing: StreamBuilder<BluetoothDevice>(
              stream: homeBloc.outGetConnectedDevice,
              builder: (context, snap) {
                return Offstage(
                  // todo 这里应当使用一个流, 或者使用 redux来管理......................
                  offstage: false,
                  child: RaisedButton(
                    child: Text("Check for updates"),
                    onPressed: () {
                      settingsBloc.inAddUpdateCmd.add(UpdateCtrlCmd(OadPhase.INIT_OAD, context, bleDevice: snap.data));
                    },
                  ),
                );
              }),
          initiallyExpanded: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Update Phrase  ",
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                  Text(
                    updatePhaseMsg,
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Text(
                "Total\nProgress",
                textAlign: TextAlign.center,
                style: greyTextStyle,
              ),
              title: LinearProgressIndicator(
                value: snap.data.sendFirmProgress,
              ),
              trailing: Text(
                "${(snap.data.phraseProgress * 100).toStringAsFixed(2)}%",
                style: greyTextStyle,
              ),
            ),
            // 计时............................................................
            StreamBuilder<int>(
              stream: settingsBloc.outCurrentTime,
              initialData: 0,
              builder: (context, snap) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                child: Text("${snap.data/1000} sec"),
              ),
            ),
          ],
        );
      },
    );
  }
}
