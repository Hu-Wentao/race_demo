import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

class StoreProvider<S> extends InheritedWidget {
  final Store<S> _store;

  const StoreProvider({
    Key key,
    @required Store<S> store,
    @required Widget child,
  })  : assert(store != null),
        assert(child != null),
        _store = store,
        super(key: key, child: child);

  static Store<S> of<S>(BuildContext context) {
    final type = _typeOf<StoreProvider<S>>();
    final provider =
        context.inheritFromWidgetOfExactType(type) as StoreProvider<S>;

    if (provider == null) throw StoreProviderError(type);

    return provider._store;
  }

  static Type _typeOf<T>() => T;

  @override
  bool updateShouldNotify(StoreProvider<S> oldWidget) =>
      _store != oldWidget._store;
}

typedef ViewModelBuilder<ViewModel> = Widget Function(
  BuildContext context,
  ViewModel vm,
);

typedef StoreConverter<S, ViewModel> = ViewModel Function(
  Store<S> store,
);

typedef OnInitCallback<S> = void Function(
  Store<S> store,
);

typedef OnDisposeCallback<S> = void Function(
  Store<S> store,
);

typedef IgnoreChangeTest<S> = bool Function(S state);

typedef OnWillChangeCallback<ViewModel> = void Function(ViewModel viewModel);

typedef OnDidChangeCallback<ViewModel> = void Function(ViewModel viewModel);

typedef OnInitialBuildCallback<ViewModel> = void Function(ViewModel viewModel);

class StoreConnector<S, ViewModel> extends StatelessWidget {
  final ViewModelBuilder<ViewModel> builder;

  final StoreConverter<S, ViewModel> converter;

  final bool distinct;

  final OnInitCallback<S> onInit;

  final OnDisposeCallback<S> onDispose;

  final bool rebuildOnChange;

  final IgnoreChangeTest<S> ignoreChange;

  final OnWillChangeCallback<ViewModel> onWillChange;

  final OnDidChangeCallback<ViewModel> onDidChange;
  final OnInitialBuildCallback<ViewModel> onInitialBuild;

  StoreConnector({
    Key key,
    @required this.builder,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  })  : assert(builder != null),
        assert(converter != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _StoreStreamListener<S, ViewModel>(
      store: StoreProvider.of<S>(context),
      builder: builder,
      converter: converter,
      distinct: distinct,
      onInit: onInit,
      onDispose: onDispose,
      rebuildOnChange: rebuildOnChange,
      ignoreChange: ignoreChange,
      onWillChange: onWillChange,
      onDidChange: onDidChange,
      onInitialBuild: onInitialBuild,
    );
  }
}

class StoreBuilder<S> extends StatelessWidget {
  static Store<S> _identity<S>(Store<S> store) => store;

  final ViewModelBuilder<Store<S>> builder;
  final bool rebuildOnChange;

  final OnInitCallback<S> onInit;

  final OnDisposeCallback<S> onDispose;

  final OnWillChangeCallback<Store<S>> onWillChange;

  final OnDidChangeCallback<Store<S>> onDidChange;

  final OnInitialBuildCallback<Store<S>> onInitialBuild;

  StoreBuilder({
    Key key,
    @required this.builder,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<S, Store<S>>(
      builder: builder,
      converter: _identity,
      rebuildOnChange: rebuildOnChange,
      onInit: onInit,
      onDispose: onDispose,
      onWillChange: onWillChange,
      onDidChange: onDidChange,
      onInitialBuild: onInitialBuild,
    );
  }
}

class _StoreStreamListener<S, ViewModel> extends StatefulWidget {
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<S, ViewModel> converter;
  final Store<S> store;
  final bool rebuildOnChange;
  final bool distinct;
  final OnInitCallback<S> onInit;
  final OnDisposeCallback<S> onDispose;
  final IgnoreChangeTest<S> ignoreChange;
  final OnWillChangeCallback<ViewModel> onWillChange;
  final OnDidChangeCallback<ViewModel> onDidChange;
  final OnInitialBuildCallback<ViewModel> onInitialBuild;

  _StoreStreamListener({
    Key key,
    @required this.builder,
    @required this.store,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StoreStreamListenerState<S, ViewModel>();
  }
}

class _StoreStreamListenerState<S, ViewModel>
    extends State<_StoreStreamListener<S, ViewModel>> {
  Stream<ViewModel> stream;
  ViewModel latestValue;

  @override
  void initState() {
    _init();

    super.initState();
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(widget.store);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(_StoreStreamListener<S, ViewModel> oldWidget) {
    if (widget.store != oldWidget.store) {
      _init();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _init() {
    if (widget.onInit != null) {
      widget.onInit(widget.store);
    }

    latestValue = widget.converter(widget.store);

    if (widget.onInitialBuild != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialBuild(latestValue);
      });
    }

    var _stream = widget.store.onChange;

    if (widget.ignoreChange != null) {
      _stream = _stream.where((state) => !widget.ignoreChange(state));
    }

    stream = _stream.map((_) => widget.converter(widget.store));

    if (widget.distinct) {
      stream = stream.where((vm) {
        final isDistinct = vm != latestValue;

        return isDistinct;
      });
    }

    stream =
        stream.transform(StreamTransformer.fromHandlers(handleData: (vm, sink) {
      latestValue = vm;

      if (widget.onWillChange != null) {
        widget.onWillChange(latestValue);
      }

      if (widget.onDidChange != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDidChange(latestValue);
        });
      }

      sink.add(vm);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return widget.rebuildOnChange
        ? StreamBuilder<ViewModel>(
            stream: stream,
            builder: (context, snapshot) => widget.builder(
              context,
              snapshot.hasData ? snapshot.data : latestValue,
            ),
          )
        : widget.builder(context, latestValue);
  }
}

class StoreProviderError extends Error {
  Type type;

  StoreProviderError(this.type);

  @override
  String toString() {
    return '''
    Error: No $type found. To fix, please try:
       *使用StoreProvider<State>包装您的MaterialApp，
        而不是单独的路由
        
        *向您的 Store<State> 提供完整的类型信息，
        StoreProvider<State>和StoreConnector<State, ViewModel>
        *确保使用一致和完整的导入。
      ''';
  }
}
