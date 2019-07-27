// Copyright 2019-07-27, Hu-Wentao.
// Email: hu.wentao@outlook.com
// All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';

//class TestTimer extends StatefulWidget {
//  @override
//  State<StatefulWidget> createState() {
//    return _TestTimer();
//  }
//}

//class _TestTimer extends State<TestTimer> {
//  Timer _timer;
//  int _timeCounter = 0;
//
////  @override
////  Widget build(BuildContext context) {
//////    return GestureDetector(
////////      onTap: () {
////////        //开始倒计时
////////        startCountdownTimer();
////////      }
//////      },
//////      child: Text(
//////        ),
//////      ),
//////    );
////  }
//
//  void startCountdownTimer() {
//    const oneSec = const Duration(seconds: 1);
//    var callback = (timer) => {setState(() => _timeCounter++)};
//    _timer = Timer.periodic(oneSec, callback);
//  }
//
//  @override
//  void dispose() {
//    super.dispose();
//    if (_timer != null) {
//      _timer.cancel();
//    }
//  }
//}
