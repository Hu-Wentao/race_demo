package com.example.race_demo;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {


  //申明方法名
  private static final String BLUETOOTH_CHANNEL = "bean.racehf.com/bluetooth";

  private BluetoothManager bluetoothManager = null;   //初始化

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), BLUETOOTH_CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if ("openBluetooth".equals(methodCall.method)) {
                  if (supportBluetooth()) {            //检测真机是否支持蓝牙
                    openBluetooth();              //打开蓝牙
                    result.success("蓝牙已经被开启");
                  } else {
                    result.error("设备不支持蓝牙", null, null);
                  }
                } else {
                  throw new RuntimeException("调用方法失败! 请检查方法名称!");
                }
              }
            }
    );
  }

  //是否支持蓝牙
  private boolean supportBluetooth() {
    return (bluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE)) != null;
  }

  //打开蓝牙
  private void openBluetooth() {
    if(bluetoothManager.getAdapter().isEnabled()){
      return;
    }
    startActivityForResult(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), 1);
  }

}