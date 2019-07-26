// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter/material.dart';

abstract class BaseBloc {
  void dispose();
}

class BlocProvider<T extends BaseBloc> extends StatefulWidget {
  final T bloc;
  final Widget child;

  const BlocProvider({Key key, this.bloc, this.child}) : super(key: key);

  @override
  _BlocProviderState createState() => _BlocProviderState();

  /// 获取 BLoC
  static T of<T extends BaseBloc>(BuildContext context) {
    final type = _typeOf<BlocProvider<T>>();
    BlocProvider<T> provider = context.ancestorWidgetOfExactType(type);
    return provider.bloc;
  }

  static _typeOf<T>() => T;
}

class _BlocProviderState<T> extends State<BlocProvider<BaseBloc>> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
