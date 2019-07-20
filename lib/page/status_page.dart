import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/redux/redux.dart';
import 'package:race_demo/redux/redux_app_action.dart';
import 'package:race_demo/redux/redux_app_state.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';
import 'package:race_demo/bloc/status_page_bloc.dart';
import 'package:race_demo/bloc/base_bloc.dart';

class StatusPage extends StatelessWidget {
  final String title;

  const StatusPage({Key key, this.title}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final StatusPageBloc _bloc = BlocProvider.of<StatusPageBloc>(context);
    return StoreConnector<ReduxAppState, String>(
        converter: (store) => store.state.appInfo,
        builder: (context, appInfo) {
          return Scaffold(
            appBar: AppBar(
              title: Text(this.title),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 48),
              child: SingleChildScrollView(
                  child: Column(
                children: <Widget>[
                  TextDivider(
                    "Device Status",
                    padLTRB: const [16, 8, 16, 0],
                    showDivider: false,
                  ),
                  _buildInfoBlock(context, _buildDeviceStatus(context, _bloc)),
                  TextDivider(
                    "Position Information",
                    padLTRB: const [16, 8, 16, 0],
                    showDivider: false,
                  ),
                  _buildInfoBlock(context, _buildPositionInformation(context)),
                  TextDivider(
                    "Position Confidence",
                    padLTRB: const [16, 8, 16, 0],
                    showDivider: false,
                  ),
                  _buildInfoBlock(context, _buildPositionConfidence(context)),
                ],
              )),
            ),
          );
        });
  }

  // 对控件的包装
  _buildInfoBlock(BuildContext context, List<Widget> childrenList) {
    return RadiusContainer(
      child: Column(
        children: childrenList,
      ),
    );
  }

  _buildDeviceStatus(BuildContext context, StatusPageBloc bloc) {
    return <Widget>[
      ListTile(
        title: Text("Connecting Device"),
        trailing: StreamBuilder<BtnStreamOpInfo>(
          stream: bloc.outGetBtnState,
          initialData: BtnStreamOpInfo(BleScanState.STOP_SCAN, null),
          builder: (context, snapshot) {
            return _buildBtnBy(snapshot.data, bloc.inBleOperator, context);
          },
        ),
      ),
      ListTile(
        title: Text("GPS Battery"),
      ),
      ListTile(
        title: Text("Firmware Version"),
      ),
    ];
  }

  _buildPositionInformation(BuildContext context) {
    return <Widget>[
      ListTile(
        title: Text("Latitude"),
      ),
      ListTile(
        title: Text("Longitude"),
      ),
      ListTile(
        title: Text("Altitude"),
      ),
      ListTile(
        title: Text("UTC"),
      ),
      ListTile(
        title: Text("Heading"),
      ),
      ListTile(
        title: Text("Speed"),
      ),
    ];
  }

  _buildPositionConfidence(BuildContext context) {
    return <Widget>[
      ListTile(
        title: Text("Horizontal"),
      ),
      ListTile(
        title: Text("Vertical"),
      ),
      ListTile(
        title: Text("3D"),
      ),
    ];
  }

////////////////////////////////////////////////////////////////////////////////
  _buildBtnBy(BtnStreamOpInfo info, StreamSink<BleOpInfo> inBleOperator, BuildContext context) {
    switch (info.state) {
      case BleScanState.SCANNING:
        return RaisedButton(
          child: Text("Scanning..."),
          onPressed: () {
            print('StatusPage._buildBtnBy 停止扫描...');
            inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING, null));
          },
        );
      case BleScanState.STOP_SCAN:
        return RaisedButton(
            child: Text("Tap to Scan"),
            onPressed: () {
              print('StatusPage._buildBtnBy 点击按钮, 开始扫描');
              inBleOperator.add(BleOpInfo(Operate.CHECK_OPEN_BLE, null));
            });
      case BleScanState.CONNECTING:
        return RaisedButton(
            child: Text("Connecting..."),
            onPressed: () {
              inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING, null));
            });
        break;
      case BleScanState.PLEASE_OPEN_BLE:
        return Text(
          "Please Open Bluetooth",
          style: TextStyle(color: Colors.red),
        );
        break;
      case BleScanState.PLEASE_SELECT_DEVICE:
        List<BluetoothDevice> deviceList = info.data;
        return RaisedButton(
            child: Text("Please Tap To Select Device"),
            onPressed: () {
              //todo 添加一个弹出框, 展示 list,
              print('StatusPage._buildBtnBy 此处应当弹出dialog, 手动选择设备');
              // del VVV
              deviceList.forEach((d) {
                switch (d.name) {
//                  case "RaceDB_0020":
//                  case "RaceDB_0021":
                  case "RaceDB_0010":
                  case "RaceDB_0011":
                  case "Race_0002":
                    print(
                        'StatusPage._buildBtnBy 发现列表找包含: ${d.name} 已自动选择该设备 #### todo ');
                    inBleOperator.add(BleOpInfo(Operate.CONNECT_DEVICE, d));
                    break;
                }
              });
              // del AAA
            });
        break;
      case BleScanState.SHOW_CONNECTED_DEVICE:

//        StoreProvider.of(context).state;
        return Text("${(info.data as BluetoothDevice).name}");
        break;
    }
  }
}
