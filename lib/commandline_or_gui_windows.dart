/*
  Bradley Honeyman
  March 16, 2022
 */

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Provides ability to write to terminal stdout & stderr
/// and the ability to run in terminal and or gui
/// terminal = shell in terminology
class CommandlineOrGuiWindows {
  static const MethodChannel _channel = MethodChannel("commandline_or_gui_windows");

  /// send data to stdout
  /// will send to default stdout if terminal not set as stdout
  static Future<void> stdout(String out) async {
    await _channel.invokeMethod(
      "printToTerminal",
      {
        "out": out,
      },
    );
  }

  /// send data to sdterr
  /// will send to default stderr if terminal not set as stderr
  static Future<void> stderr(String out) async {
    await _channel.invokeMethod(
      "printToTerminalError",
      {
        "out": out,
      },
    );
  }

  /// hides the gui
  /// the gui still exists, but cannot be interacted with by the user
  static Future<void> hideWindow(String out) async {
    await _channel.invokeMethod(
      "hideWindow",
    );
  }

  /// runs runApp. Is a replacment for runApp
  /// if commandline = true run app in commandline
  /// otherwise load passed gui widget ex material app
  /// closeOnCompleteCommandlineOptionOnly, closes app after supplied code (afterLoaded) is run, unless is false
  /// should only set closeOnCompleteCommandlineOptionOnly as false if debugging
  /// placeHolderAfterLoadedRunning is the widget displayed while afterLoaded is running
  /// placeHolderAfterLoadedRunning defaults to a circular progress indicator
  static Future<void> runAppCommandlineOrGUI({
    Widget? gui,
    Future<void> Function()? afterLoaded,
    bool commandline = true,
    bool closeOnCompleteCommandlineOptionOnly = true,
    Widget placeHolderAfterLoadedRunning = const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
  }) async {
    // thow err if in gui mode and no gui
    if (gui == null && !commandline) {
      throw Exception("Must pass a gui widget if commandline == false");
    }

    // if in gui mode return gui
    if (!commandline) {
      runApp(gui!);
      return;
    }

    // err if afterLoaded passed and null
    if (afterLoaded == null) {
      throw Exception("Must pass a afterLoaded Future if in commandline mode");
    }

    // run in commandline mode if not in gui mode
    runApp(_CommandlineWidget(
      afterLoaded: afterLoaded,
      closeOnComplete: closeOnCompleteCommandlineOptionOnly,
      placeHolder: placeHolderAfterLoadedRunning,
    ));
  }
}

// place holder widget, shown before app closes
class _CommandlineWidget extends StatefulWidget {
  final Future<void> Function() afterLoaded;
  final bool closeOnComplete;
  final Widget placeHolder;

  const _CommandlineWidget({
    Key? key,
    required this.afterLoaded,
    required this.closeOnComplete,
    required this.placeHolder,
  }) : super(key: key);

  @override
  _CommandlineWidgetState createState() {
    return _CommandlineWidgetState();
  }
}

// place holder state
class _CommandlineWidgetState extends State<_CommandlineWidget> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  // runs after widget init, this way it is fairly certain that flutter has loaded
  // closes app on complete unless told not to
  Future<void> _run() async {
    // run code passed
    await widget.afterLoaded();

    // close app on complete unless otherwise specified
    if (widget.closeOnComplete) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.placeHolder;
  }
}
