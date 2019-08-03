import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:race_demo/provider/race_model.dart';
import 'package:race_demo/utils/ble_util.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';
import 'package:race_demo/bloc/status_page_bloc.dart';
import 'package:race_demo/bloc/base_bloc.dart';

class StatusPage extends StatelessWidget {

  const StatusPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StatusPageBloc _bloc = BlocProvider.of<StatusPageBloc>(context);
    // 从性能上考虑, 应该在此处进行 检测蓝牙状态, 检测是否正在扫描等...
//      print('StatusPage.build 检查并打开蓝牙, 然后');
//      _bloc.inBleOperator.add(OperateInfo(Operate.CHECK_OPEN_BLE, null));

    return Scaffold(
      appBar: AppBar(
        title: Text("Status"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 48),
        child: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            TextDivider("Device Status"),
            _buildInfoBlock(context, _buildDeviceStatus(context, _bloc)),
            TextDivider("Position Information"),
            _buildInfoBlock(context, _buildPositionInformation(context)),
            TextDivider("Position Confidence"),
            _buildInfoBlock(context, _buildPositionConfidence(context)),
          ],
        )),
      ),
    );
  }

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
        title: Text("Device"),
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
        title: Text("Sats"),
      ),
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
        title: Text("HDOP"),
      ),
      ListTile(
        title: Text("Position"),
      ),
    ];
  }

  _buildBtnBy(BtnStreamOpInfo info, StreamSink<BleOpInfo> inBleOperator,
      BuildContext context) {
    switch (info.state) {
      case BleScanState.SCANNING:
        return RaisedButton(
          child: const Text("Scanning..."),
          onPressed: () {
            print('StatusPage._buildBtnBy 停止扫描...');
            inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING, null));
          },
        );
      case BleScanState.STOP_SCAN:
        return RaisedButton(
            child: const Text("Tap to Scan"),
            onPressed: () {
              print('StatusPage._buildBtnBy 点击按钮, 开始扫描');
              inBleOperator.add(BleOpInfo(Operate.CHECK_OPEN_BLE, null));
            });
      case BleScanState.CONNECTING:
        return RaisedButton(
            child: const Text("Connecting..."),
            onPressed: () {
              inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING, null));
            });
        break;
      case BleScanState.PLEASE_OPEN_BLE:
        const Text text = const Text(
          "Please Open Bluetooth",
          style: TextStyle(color: Colors.red),
        );
        return (Platform.isAndroid)
            ? RaisedButton(
                child: text,
                onPressed: () => BleUtil.openBluetooth(),
              )
            : text;
      case BleScanState.PLEASE_SELECT_DEVICE:
        List<BluetoothDevice> deviceList = info.data;
        return RaisedButton(
            child: const Text("Please Select Device"),
            onPressed: () {
              //todo 添加一个弹出框, 展示 list,
              print('StatusPage._buildBtnBy 此处应当弹出dialog, 手动选择设备');
              // del VVV
              deviceList.forEach((d) {
                switch (d.name) {
                  case "RaceDB_0010":
                  case "RaceDB_0011":
                  case "Race_0002":
                  case "Race_OAD1":
                  case "Race_OAD2":
                    print(
                        'StatusPage._buildBtnBy 发现列表找包含: ${d.name} 已自动选择该设备 #### todo ');
                    inBleOperator.add(BleOpInfo(Operate.CONNECT_DEVICE,context, device:d));
                    break;
                }
              });
              // del AAA
            });
        break;
      case BleScanState.SHOW_CONNECTED_DEVICE:
        // todo 将以下内容转移到bloc中
//        // 发送给全局状态, 持有该设备
//        Provider.of<AppState>(context)
//            .setCurrentDevice(bleDevice: info.data as BluetoothDevice);
        return RaisedButton(
          child: Text("${(info.data as BluetoothDevice).name}"),
          onPressed: () => inBleOperator.add(BleOpInfo(
              Operate.DISCONNECT_DEVICE, context, device: info.data as BluetoothDevice)),
        );
    }
  }
}
