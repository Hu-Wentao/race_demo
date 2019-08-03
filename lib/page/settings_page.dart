import 'package:flutter/material.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/provider/race_model.dart';
import 'package:race_demo/provider/oad_model.dart';
import 'package:race_demo/provider/store.dart';
import 'package:race_demo/widget/radius_stream_expansion_tile.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

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
                child: _buildUpgradeFirmware(context, _settingsBloc),
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

  _buildUpgradeFirmware(BuildContext context, SettingsPageBloc settingsBloc) {
    final greyTextStyle =
    TextStyle(color: Theme
        .of(context)
        .textTheme
        .caption
        .color);

    return StreamBuilder<UpdateProgressInfo>(
      stream: settingsBloc.outUpdateProgress,
      initialData: UpdateProgressInfo(
        null,
        "init",
        phraseProgress: 0.0,
      ),
      builder: (context, snap) {
        final String oadPhaseMsg = snap.data.phaseMsg;

        var tile = RadiusStreamExpansionTile(
          ctrlExpand: settingsBloc.outUpdateProgress.map((upi)=>upi.oadPhase!=OadPhase.UN_OAD),
          title: Text("Upgrade Firmware"),
          trailing: Store.connect<RaceModel>(
            builder: (context, raceSnap, child) {
              // 查询OAD状态 与 当前已连接的设备

              return Offstage(
                offstage: ((Store.value<OadModel>(context)).isOad),
                child: (raceSnap.currentDevice == null)
                    ? Text("Please Connect Device")
                    : RaisedButton(
                    child: Text("Check for updates"),
                    onPressed: () {
                      settingsBloc.inAddUpdateCmd.add(UpdateCtrlCmd(OadPhase.INIT_OAD, context));
                    }),
              );
            },
          ),
//          trailing: Consumer<RaceModel>(
//            builder: (context, appState, _) {
////              var oadState = appState.currentOadState;
//              var device = appState.currentDevice;
//
//              return (oadState.isOad || device == null)
//                  ? Text("Please Connect Device")
//                  : RaisedButton(
//                      child: Text("Check for updates"),
//                      onPressed: () {
//                        //todo  可以考虑直接传入 OadState
//                        _checkAndUpdateFirmware(
//                            device, settingsBloc.inAddOadCmd);
//                      });
//            },
//          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "OAD Message ",
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                  Text(
                    oadPhaseMsg,
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Text(
                "OAD Progress",
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
              builder: (context, snap) =>
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                    child: Text("${snap.data / 1000} sec"),
                  ),
            ),
          ],
        );
//        tile.handleTap();
        return tile;
      },
    );
  }
}
