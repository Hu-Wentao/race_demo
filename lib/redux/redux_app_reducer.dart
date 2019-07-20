
// ignore: missing_return
import 'package:race_demo/redux/redux_app_action.dart';
import 'package:race_demo/redux/redux_app_state.dart';

ReduxAppState appReducer(ReduxAppState state, action){
  switch(action){
    case ReduxAppAction.setConnectedDevice:
      return ReduxAppState(state.device);
    case ReduxAppAction.removeConnectDevice:
      return ReduxAppState(null);
    default:
      print('deviceReducer 异常!!!!!!!!!!!!!!!!!!!!!!!!!!!! 空的case !!');
      return null;
  }
}