import 'package:flutter/material.dart';
import 'package:race_demo/redux/redux.dart';
import 'package:race_demo/redux/redux_app_state.dart';
import 'package:redux/redux.dart';
import 'package:race_demo/redux/redux_app_reducer.dart';

import 'page/home_page.dart';

void main() {
  final Store<ReduxAppState> store = Store<ReduxAppState>(
      appReducer,
      initialState: ReduxAppState.initState()
  );
  runApp(MaterialApp(
    title: "Race demo",
    theme: ThemeData(
      primarySwatch: Colors.red,
    ),
    home: AppRedux(store),
  ));
}

class AppRedux extends StatelessWidget{
  final store;
  const AppRedux( this.store, {Key key,}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: HomePage(),
    );
  }

}