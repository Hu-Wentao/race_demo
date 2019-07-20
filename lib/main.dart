import 'package:flutter/material.dart';
import 'package:race_demo/redux/redux.dart';
import 'package:race_demo/redux/redux_app_state.dart';
import 'package:redux/redux.dart';
import 'package:race_demo/redux/redux_app_reducer.dart';

import 'bloc/base_bloc.dart';
import 'bloc/home_bloc.dart';
import 'page/home_page.dart';

void main() {
  runApp(AppRedux());
}

class AppRedux extends StatelessWidget {
  final Store<ReduxAppState> store =
  Store<ReduxAppState>(appReducer, initialState: ReduxAppState.initState());

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
        store: store,
        child: MaterialApp(
          title: "Race demo",
          theme: ThemeData(
            primarySwatch: Colors.red,
          ),
          home: BlocProvider<HomeBloc>(
            bloc: HomeBloc(),
            child: HomePage(),
          ),
        ));
  }
}
